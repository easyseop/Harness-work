#!/usr/bin/env python3
# =====================================================================
# spine.py  ·  은행 반입 하네스 — 중앙 오케스트레이터 (얇은 Spine)
# =====================================================================
# 설계 원칙(INV-1): Spine 은 정책/업무 로직을 갖지 않는다.
#   하네스가 manifest 로 선언하고, Spine 은 manifest 대로 부르고 모은다.
#
# Spine 이 하는 일 (00-spine-and-manifest-spec.md §3, §5):
#   1) manifest.yaml 이 있는 디렉터리를 하네스로 발견한다.
#   2) requires 의존성으로 위상정렬한다(순환=설계오류).
#   3) 단계(classify/build/verify/import/reproduce)별로 hooks 된 하네스를 부른다.
#   4) appliesWhen 조건으로 적용 대상만 남긴다.
#   5) 각 하네스의 게이트를 실행하고 표준 결과(JSON)를 모은다.
#   6) blocking 게이트가 실패하면 그 단계 종료 후 진행을 멈춘다.
#
# 사용법:
#   spine.py discover [경로]            하네스 목록 보기
#   spine.py plan [경로]                단계별 실행 순서 보기
#   spine.py run --demo [경로]          예시 입력으로 전체 게이트 실행
#
# 요구: python3 + pyyaml
# =====================================================================
import sys, os, json, subprocess

try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml")
    sys.exit(2)

STAGES = ["classify", "build", "verify", "import", "reproduce"]
SUPPORTED_MANIFEST_VERSIONS = {"0.1"}
HERE = os.path.dirname(os.path.abspath(__file__))
DEFAULT_ROOT = os.path.dirname(HERE)  # spine 의 상위 = 키트들이 있는 곳


# ---------------------------------------------------------------------
# 1) 발견 (discover) — manifest.yaml 스캔
# ---------------------------------------------------------------------
def discover(root):
    harnesses = {}
    for entry in sorted(os.listdir(root)):
        path = os.path.join(root, entry)
        manifest_path = os.path.join(path, "manifest.yaml")
        if os.path.isdir(path) and os.path.isfile(manifest_path):
            m = yaml.safe_load(open(manifest_path, encoding="utf-8"))
            if not isinstance(m, dict) or "id" not in m:
                continue
            mv = str(m.get("manifestVersion", ""))
            if mv not in SUPPORTED_MANIFEST_VERSIONS:
                print(f"⚠️  로드 거부: {entry} (manifestVersion={mv} 미지원)")
                continue
            m["_dir"] = path
            harnesses[m["id"]] = m
    return harnesses


# ---------------------------------------------------------------------
# 2) 위상정렬 (requires 의존성) — 순환이면 설계오류
# ---------------------------------------------------------------------
def topo_sort(harnesses):
    visited, order, stack = set(), [], set()

    def visit(hid):
        if hid in order_set:
            return
        if hid in stack:
            raise ValueError(f"순환 의존 발견(설계오류): {hid}")
        if hid not in harnesses:
            return  # 외부 의존은 건너뜀(없어도 됨)
        stack.add(hid)
        for dep in harnesses[hid].get("requires", []) or []:
            visit(dep)
        stack.discard(hid)
        order.append(hid)
        order_set.add(hid)

    order_set = set()
    for hid in harnesses:
        visit(hid)
    return order


# ---------------------------------------------------------------------
# 3) 단계별 실행 계획
# ---------------------------------------------------------------------
def plan(harnesses):
    ordered = topo_sort(harnesses)
    result = {}
    for stage in STAGES:
        stage_harnesses = [
            hid for hid in ordered
            if stage in (harnesses[hid].get("hooks") or [])
        ]
        result[stage] = stage_harnesses
    return result


# ---------------------------------------------------------------------
# 4) 게이트 실행 + 표준 결과 수집
# ---------------------------------------------------------------------
def run_gate(harness, gate, demo_inputs):
    """게이트 1개 실행 → (result, message)."""
    runner = gate.get("runner")
    runner_path = os.path.join(harness["_dir"], runner)
    if not os.path.isfile(runner_path):
        return "skipped", f"runner 없음: {runner}"

    args = demo_inputs.get(harness["id"], {}).get(gate["id"])
    if args is None:
        return "skipped", "demo 입력 미정의"

    # 게이트를 하네스 폴더에서 실행 → 파일 인자는 상대경로로, 날짜 등 리터럴은 그대로 전달
    cmd = ["bash", runner_path] + [str(a) for a in args]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=60,
                              cwd=harness["_dir"])
    except Exception as e:
        return "failed", f"실행오류: {e}"
    if proc.returncode == 0:
        return "passed", proc.stdout.strip().splitlines()[-1] if proc.stdout.strip() else ""
    return "failed", (proc.stdout.strip() or proc.stderr.strip()).splitlines()[-1] if (proc.stdout or proc.stderr).strip() else f"exit {proc.returncode}"


def load_valid_waivers(path):
    """waivers 파일에서 '필수항목 있고 만료 안 된' 예외의 게이트 id 집합을 돌려준다."""
    import datetime
    if not path or not os.path.isfile(path):
        return set()
    today = datetime.date.today()
    valid = set()
    for w in (yaml.safe_load(open(path, encoding="utf-8")) or {}).get("waivers", []):
        complete = all(w.get(k) for k in ("gate", "reason", "approved_by", "expires_on"))
        try:
            ok = complete and datetime.date.fromisoformat(str(w["expires_on"])) >= today
        except ValueError:
            ok = False
        if ok:
            valid.add(w["gate"])
    return valid


def resolve_mapping(flags, flag, demo_file):
    """--demo → 번들 데모 파일 / <flag>=<경로> → 실제 프로젝트 입력표."""
    if "--demo" in flags:
        path = os.path.join(HERE, demo_file)
    else:
        path = next((f.split("=", 1)[1] for f in flags if f.startswith(flag + "=")), None)
    if path and os.path.isfile(path):
        return yaml.safe_load(open(path, encoding="utf-8")) or {}
    return None


def run(harnesses, demo_inputs, valid_waivers=()):
    ordered_by_stage = plan(harnesses)
    all_results = []
    stopped = False

    for stage in STAGES:
        hids = ordered_by_stage[stage]
        if not hids:
            continue
        print(f"\n===== 단계: {stage} =====")
        for hid in hids:
            h = harnesses[hid]
            gates = [g for g in (h.get("gates") or []) if g.get("phase") == stage]
            result_obj = {
                "harness": hid,
                "version": h.get("version"),
                "phase": stage,
                "status": "passed",
                "gates": [],
            }
            if not gates:
                print(f"  · {hid}: (이 단계 게이트 없음 — 산출물 단계)")
            for g in gates:
                res, msg = run_gate(h, g, demo_inputs)
                if res == "failed" and g.get("waiverable") and g["id"] in valid_waivers:
                    res = "waived"          # 만료 없는 유효 예외 → 통과 처리(기록 남김)
                result_obj["gates"].append({"id": g["id"], "result": res, "message": msg})
                icon = {"passed": "✅", "failed": "❌", "skipped": "➖", "waived": "🟡"}.get(res, "?")
                print(f"  {icon} {hid} / {g['id']}: {res}  {('· '+msg) if msg else ''}")
                if res == "failed":
                    result_obj["status"] = "failed"
                    if g.get("blocking"):
                        stopped = True
            all_results.append(result_obj)
        if stopped:
            print(f"\n⛔ blocking 게이트 실패 — '{stage}' 단계 종료 후 진행 중단 (명세 §3.3)")
            break

    return all_results, stopped


# ---------------------------------------------------------------------
# 번들 조립 (증거 수렴점) — 실행 결과에서 번들을 자동으로 만든다
# ---------------------------------------------------------------------
def assemble_bundle(hs, demo_inputs, demo_evidence, out_dir):
    import shutil, datetime
    # 1) 파이프라인 실행 (모든 게이트 통과해야 번들 가능)
    results, stopped = run(hs, demo_inputs)
    if stopped:
        print("\n⛔ 검증이 중단되어 번들을 만들 수 없습니다 (먼저 모든 게이트를 통과해야 함).")
        return False

    # 2) 하네스별 상태 집계 (한 단계라도 실패면 failed)
    agg = {}
    for r in results:
        prev = agg.get(r["harness"], "passed")
        agg[r["harness"]] = "failed" if (r["status"] == "failed" or prev == "failed") else "passed"

    # 3) 출력 폴더 준비
    if os.path.exists(out_dir):
        shutil.rmtree(out_dir)
    ev_dir = os.path.join(out_dir, "evidence")
    os.makedirs(ev_dir)

    # 4) 각 하네스의 증거(아티팩트)를 번들로 복사 + 목록 작성
    evidence_list = []
    for hid, artifact_rel in demo_evidence.items():
        if hid not in hs:
            continue
        src = os.path.join(hs[hid]["_dir"], artifact_rel)
        if not os.path.isfile(src):
            print(f"  ⚠️  아티팩트 없음: {hid} → {artifact_rel}")
            continue
        os.makedirs(os.path.join(ev_dir, hid), exist_ok=True)
        shutil.copy(src, os.path.join(ev_dir, hid, os.path.basename(src)))
        ev_meta = (hs[hid].get("evidence") or [{}])[0]
        evidence_list.append({
            "harness": hid,
            "id": ev_meta.get("id", hid),
            "status": agg.get(hid, "passed"),
            "required": bool(ev_meta.get("requiredForImport", True)),
            "file": f"evidence/{hid}/{os.path.basename(src)}",
        })

    # 5) project id (분류 결과 예시에서 읽어옴)
    project = "PRJ-DEMO"
    pp = hs.get("policy-profile")
    if pp:
        prof = os.path.join(pp["_dir"], "profile.example.json")
        if os.path.isfile(prof):
            try:
                project = json.load(open(prof, encoding="utf-8")).get("project", {}).get("id", project)
            except Exception:
                pass

    # 6) bundle-manifest.yaml 자동 생성
    bundle = {"bundle": {
        "project": project,
        "version": "1.0.0",
        "created_on": datetime.date.today().isoformat(),
        "items": {
            "source": "src/",
            "lockfile": "poetry.lock",
            "sbom": "sbom.spdx.json",
            "contracts": "evidence/internal-solution/",
            "manifest": "manifests/",
            "attestation": "present",
        },
        "evidence": evidence_list,
        "attestation": {
            "developer": "개발팀-A",
            "verifier": "품질검증팀",
            "approver": "반입승인책임자",
        },
        "waivers": [],
    }}
    bm_path = os.path.join(out_dir, "bundle-manifest.yaml")
    yaml.safe_dump(bundle, open(bm_path, "w", encoding="utf-8"), allow_unicode=True, sort_keys=False)

    # 6-2) 추적성(trace) — 요건 → 각 하네스가 남긴 기록·증거를 잇는다
    trace = {"trace": {"requirement": project, "links": [
        {"harness": e["harness"],
         "emits": (hs[e["harness"]].get("traceability", {}) or {}).get("emits", []),
         "evidence": e["file"]}
        for e in evidence_list
    ]}}
    yaml.safe_dump(trace, open(os.path.join(out_dir, "trace.yaml"), "w", encoding="utf-8"),
                   allow_unicode=True, sort_keys=False)

    print(f"\n📦 번들 조립 완료: {out_dir}")
    print(f"   - 증거 {len(evidence_list)}건 수집 → evidence/")
    print(f"   - bundle-manifest.yaml 자동 생성")
    print(f"   - trace.yaml 자동 생성 (요건 → 증거 추적)")

    # 7) 반입 게이트로 번들 최종 검사
    ig = hs.get("import-gate")
    if ig:
        print(f"\n▶ 반입 게이트로 번들 검사:")
        for gate in ("check-bundle-complete.sh", "check-roles-and-waivers.sh"):
            rp = os.path.join(ig["_dir"], "gates", gate)
            if os.path.isfile(rp):
                proc = subprocess.run(["bash", rp, bm_path], capture_output=True, text=True, cwd=ig["_dir"])
                last = (proc.stdout.strip().splitlines() or [""])[-1]
                print(f"   {'✅' if proc.returncode == 0 else '❌'} {gate}: {last}")
    return True


# ---------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------
def main():
    args = sys.argv[1:]
    cmd = args[0] if args else "help"
    rest = [a for a in args[1:] if not a.startswith("--")]
    flags = [a for a in args[1:] if a.startswith("--")]
    root = rest[0] if rest else DEFAULT_ROOT

    if cmd == "discover":
        hs = discover(root)
        print(f"발견된 하네스 {len(hs)}개 (경로: {root}):\n")
        for hid, m in hs.items():
            req = ", ".join(m.get("requires", []) or []) or "-"
            hooks = ", ".join(m.get("hooks", []) or [])
            print(f"  {hid:20s} v{m.get('version'):8s} hooks=[{hooks}]  requires=[{req}]")

    elif cmd == "plan":
        hs = discover(root)
        p = plan(hs)
        print(f"실행 계획 (위상정렬 + 단계별):\n")
        for stage in STAGES:
            chain = " → ".join(p[stage]) if p[stage] else "(해당 하네스 없음)"
            print(f"  [{stage:10s}] {chain}")

    elif cmd == "run":
        hs = discover(root)
        # --only=<id> : 그 하네스 + 의존(requires) 윗단만 남긴다
        only = None
        for f in flags:
            if f.startswith("--only="):
                only = f.split("=", 1)[1]
        if only:
            if only not in hs:
                print(f"❌ 하네스를 찾을 수 없음: {only}"); sys.exit(2)
            keep = set()
            def collect(hid):
                if hid in keep or hid not in hs:
                    return
                keep.add(hid)
                for dep in hs[hid].get("requires", []) or []:
                    collect(dep)
            collect(only)
            hs = {k: v for k, v in hs.items() if k in keep}
            print(f"▶ --only {only}: 대상 {sorted(keep)} (의존 윗단 포함)\n")
        inputs = resolve_mapping(flags, "--inputs", "demo-inputs.yaml")
        if inputs is None:
            print("⚠️  입력이 필요합니다: --demo 또는 --inputs=<입력표.yaml>"); sys.exit(2)
        wv = next((f.split("=", 1)[1] for f in flags if f.startswith("--waivers=")), None)
        valid_waivers = load_valid_waivers(wv)
        if valid_waivers:
            print(f"🟡 적용된 예외(waiver): {sorted(valid_waivers)}\n")
        results, stopped = run(hs, inputs, valid_waivers)
        passed = sum(1 for r in results for g in r["gates"] if g["result"] == "passed")
        failed = sum(1 for r in results for g in r["gates"] if g["result"] == "failed")
        waived = sum(1 for r in results for g in r["gates"] if g["result"] == "waived")
        skipped = sum(1 for r in results for g in r["gates"] if g["result"] == "skipped")
        print(f"\n===== 요약 =====")
        print(f"  게이트 통과 {passed} · 예외통과 {waived} · 실패 {failed} · 건너뜀 {skipped}")
        print(f"  진행상태: {'중단됨(blocking 실패)' if stopped else '끝까지 진행'}")
        # 표준 결과 저장
        out = os.path.join(HERE, "last-run.json")
        json.dump(results, open(out, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
        print(f"  표준 결과 저장: {out}")
        sys.exit(1 if failed else 0)

    elif cmd == "bundle":
        hs = discover(root)
        inputs = resolve_mapping(flags, "--inputs", "demo-inputs.yaml")
        evidence = resolve_mapping(flags, "--evidence", "demo-evidence.yaml")
        if inputs is None or evidence is None:
            print("⚠️  입력이 필요합니다: --demo 또는 --inputs=<..> --evidence=<..>"); sys.exit(2)
        ok = assemble_bundle(hs, inputs, evidence, os.path.join(HERE, "bundle-out"))
        sys.exit(0 if ok else 1)

    else:
        print(__doc__ or "사용법: spine.py [discover|plan|run --demo|bundle --demo] [경로]")


if __name__ == "__main__":
    main()
