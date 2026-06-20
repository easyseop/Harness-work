#!/usr/bin/env python3
# =====================================================================
# verify-harness.py  ·  베이스 검증기 (매니페스트 검증 + 규격 적합성)
# =====================================================================
# 하네스를 베이스에 올리기 전, "규격을 지켰는지" 자동으로 검수한다.
# (규칙이 '옳은지'는 사람이 본다 — 검증기는 '형식·안전'만 본다)
#
# 검사 항목:
#   [매니페스트]
#    1) 필수항목 있음 (manifestVersion·id·version·hooks)
#    2) 지원하는 규격 버전인지
#    3) id/version 형식
#    4) hooks 단계명이 유효한지
#    5) requires 가 실재하는 하네스인지 + 순환 없음
#    6) 게이트 runner 파일이 실제로 있는지 / phase 유효
#   [규격 적합성]
#    7) 실제 비밀값(IP·URL·키 등) 없음 (산출물 yaml/json)
#    8) 빈칸(미정·TBD) 안 남음 (manifest·예시 — 양식 제외)
#    9) 자가진단(tests) 있고 전부 통과
#
# 사용법:
#   verify-harness.py <id>        하네스 1개 검수
#   verify-harness.py --all       전체 검수
#
# 요구: python3 + pyyaml
# =====================================================================
import sys, os, re, glob, subprocess
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SUPPORTED = {"0.1"}
VALID_HOOKS = {"classify", "build", "verify", "import", "reproduce"}
VALID_PHASES = VALID_HOOKS
ID_RE = re.compile(r"^[a-z][a-z0-9-]+$")
SEMVER_RE = re.compile(r"^\d+\.\d+\.\d+$")

SECRET_PATTERNS = [
    ("실제 IP 주소",   re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b")),
    ("실제 URL",       re.compile(r"https?://[^\s'\"]+", re.I)),
    ("비밀값 지정",     re.compile(r"\b(password|passwd|pwd|secret|token|api[_-]?key|private[_-]?key)\b\s*[:=]\s*\S+", re.I)),
    ("개인키 블록",     re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("주민번호 형태",   re.compile(r"\b\d{6}[-\s]?[1-4]\d{6}\b")),
]
PLACEHOLDER = re.compile(r"\$\{[A-Z][A-Z0-9_]*\}")
SAFE_HINTS = ("예:", "example", "TBD", "최대", "최소", "0.0", "draft", "microsoft-ie")

def discover_ids():
    ids = {}
    for entry in sorted(os.listdir(ROOT)):
        mp = os.path.join(ROOT, entry, "manifest.yaml")
        if os.path.isfile(mp):
            try:
                m = yaml.safe_load(open(mp, encoding="utf-8"))
                if isinstance(m, dict) and "id" in m:
                    ids[m["id"]] = os.path.join(ROOT, entry)
            except Exception:
                pass
    return ids

def find_kit(hid, all_ids):
    if hid in all_ids:
        return all_ids[hid]
    for cand in (f"{hid}-kit", hid):
        p = os.path.join(ROOT, cand)
        if os.path.isfile(os.path.join(p, "manifest.yaml")):
            return p
    return None

def verify(hid, all_ids):
    kit = find_kit(hid, all_ids)
    checks = []
    def add(name, ok, detail=""):
        checks.append((name, ok, detail))

    if not kit:
        return [("하네스 존재", False, f"{hid} 폴더를 찾을 수 없음")]

    mp = os.path.join(kit, "manifest.yaml")
    try:
        m = yaml.safe_load(open(mp, encoding="utf-8"))
    except Exception as e:
        return [("manifest 파싱", False, str(e))]

    # 1) 필수항목
    missing = [k for k in ("manifestVersion", "id", "version", "hooks") if not m.get(k)]
    add("필수항목(manifestVersion·id·version·hooks)", not missing,
        "누락: " + ", ".join(missing) if missing else "")

    # 2) 규격 버전
    mv = str(m.get("manifestVersion", ""))
    add(f"지원 규격 버전({mv})", mv in SUPPORTED,
        f"지원: {sorted(SUPPORTED)}" if mv not in SUPPORTED else "")

    # 3) id/version 형식
    add("id 형식(소문자-하이픈)", bool(ID_RE.match(str(m.get("id", "")))), str(m.get("id")))
    add("version 형식(semver)", bool(SEMVER_RE.match(str(m.get("version", "")))), str(m.get("version")))

    # 4) hooks 유효
    hooks = m.get("hooks") or []
    bad_hooks = [h for h in hooks if h not in VALID_HOOKS]
    add("hooks 단계명 유효", not bad_hooks,
        f"알 수 없는 단계: {bad_hooks}" if bad_hooks else f"{hooks}")

    # 5) requires 실재 + 순환
    reqs = m.get("requires") or []
    unknown = [r for r in reqs if r not in all_ids]
    add("requires 가 실재 하네스", not unknown,
        f"존재하지 않음: {unknown}" if unknown else (f"{reqs}" if reqs else "없음"))
    # 순환(간단): 내 id 가 의존의 의존에 다시 나오나
    def reaches(start, target, seen=None):
        seen = seen or set()
        for d in (yaml.safe_load(open(os.path.join(all_ids[start], "manifest.yaml"), encoding="utf-8")).get("requires") or []):
            if d == target: return True
            if d in all_ids and d not in seen:
                seen.add(d)
                if reaches(d, target, seen): return True
        return False
    cyc = any(r in all_ids and reaches(r, m["id"]) for r in reqs)
    add("순환 의존 없음", not cyc, "순환 발견" if cyc else "")

    # 6) 게이트 runner 존재 / phase 유효
    gate_issues = []
    for g in (m.get("gates") or []):
        rp = os.path.join(kit, g.get("runner", ""))
        if not os.path.isfile(rp):
            gate_issues.append(f"runner 없음: {g.get('runner')}")
        if g.get("phase") not in VALID_PHASES:
            gate_issues.append(f"phase 무효: {g.get('id')}={g.get('phase')}")
    add("게이트 runner 존재·phase 유효", not gate_issues, "; ".join(gate_issues))

    # 7) 실제 비밀값 없음 (yaml/json 산출물, tests/ 와 .md 제외)
    secret_hits = []
    for f in glob.glob(os.path.join(kit, "*.yaml")) + glob.glob(os.path.join(kit, "*.yml")) + glob.glob(os.path.join(kit, "*.json")):
        for n, line in enumerate(open(f, encoding="utf-8", errors="ignore"), 1):
            if line.strip().startswith("#"):       # 설명 주석은 검사 제외
                continue
            masked = PLACEHOLDER.sub("__PH__", line)
            if any(h in line for h in SAFE_HINTS):
                continue
            for label, rx in SECRET_PATTERNS:
                mt = rx.search(masked)
                if mt:
                    secret_hits.append(f"{os.path.basename(f)}:{n} [{label}]")
    add("실제 비밀값 없음(산출물)", not secret_hits, "; ".join(secret_hits[:5]))

    # 8) 빈칸(미정/TBD) 없음 — manifest + *.example.* (양식·정책 제외)
    tbd_hits = []
    scan_for_tbd = [mp] + glob.glob(os.path.join(kit, "*.example.*")) + glob.glob(os.path.join(kit, "*.messenger.*"))
    for f in scan_for_tbd:
        for n, line in enumerate(open(f, encoding="utf-8", errors="ignore"), 1):
            if line.strip().startswith("#"):       # 설명 주석은 검사 제외
                continue
            if re.search(r"(미정|TBD)", line) and "예:" not in line and "선택지" not in line:
                tbd_hits.append(f"{os.path.basename(f)}:{n}")
    add("빈칸(미정·TBD) 없음(manifest·예시)", not tbd_hits, "; ".join(tbd_hits[:5]))

    # 9) 자가진단(tests) 있고 통과
    cases = os.path.join(kit, "tests", "cases.yaml")
    if not os.path.isfile(cases):
        add("자가진단(tests) 통과", None, "tests/cases.yaml 없음 (권장)")
    else:
        try:
            proc = subprocess.run(["python3", os.path.join(HERE, "harness-test.py"), m["id"]],
                                  capture_output=True, text=True, timeout=120)
            add("자가진단(tests) 통과", proc.returncode == 0,
                "" if proc.returncode == 0 else "일부 케이스 실패 (harness-test.py 로 확인)")
        except Exception as e:
            add("자가진단(tests) 통과", False, str(e))

    return checks

def print_report(hid, checks):
    print(f"\n▣ {hid}")
    ok = fail = warn = 0
    for name, status, detail in checks:
        if status is True:
            icon = "✅"; ok += 1
        elif status is False:
            icon = "❌"; fail += 1
        else:
            icon = "➖"; warn += 1
        line = f"   {icon} {name}"
        if detail:
            line += f"   — {detail}"
        print(line)
    return ok, fail, warn

def main():
    if len(sys.argv) < 2:
        print("사용법: verify-harness.py <id> | --all"); sys.exit(2)
    all_ids = discover_ids()
    targets = sorted(all_ids) if sys.argv[1] == "--all" else [sys.argv[1]]
    total_fail = 0
    print("=== 베이스 검증기 — 규격 적합성 검수 ===")
    for hid in targets:
        checks = verify(hid, all_ids)
        _, fail, _ = print_report(hid, checks)
        total_fail += fail
    print(f"\n===== 결과 =====")
    if total_fail == 0:
        print("  🎉 검수 통과 — 규격을 지켰습니다. (규칙이 '옳은지'는 사람 리뷰가 확인)")
    else:
        print(f"  ❌ 규격 위반 {total_fail}건 — 위 ❌ 를 고쳐야 베이스에 올릴 수 있습니다.")
    sys.exit(1 if total_fail else 0)

if __name__ == "__main__":
    main()
