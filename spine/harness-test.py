#!/usr/bin/env python3
# =====================================================================
# harness-test.py  ·  하네스 자가진단 (담당자가 자기 하네스를 검증하는 도구)
# =====================================================================
# "좋은 입력은 통과(pass), 나쁜 입력은 차단(fail)" 되는지 자동 확인한다.
# 게이트가 진짜로 거르는지(양방향) 검증 → 품질·메타 담당자의 핵심 작업.
#
# 사용법:
#   harness-test.py <하네스id>          예) harness-test.py data-standard
#   harness-test.py <하네스id> [경로]    (키트 루트 직접 지정)
#
# 동작:
#   1) <키트>/tests/cases.yaml 을 읽는다.
#   2) 각 케이스의 gate 를 manifest 에서 찾아 input 으로 실행한다.
#   3) 종료코드(0=통과 / 0아님=차단)가 expect 와 맞는지 비교한다.
#
# 요구: python3 + pyyaml
# =====================================================================
import sys, os, subprocess
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

def find_kit(hid, override=None):
    if override:
        return override
    for cand in (f"{hid}-kit", hid):
        p = os.path.join(ROOT, cand)
        if os.path.isdir(p) and os.path.isfile(os.path.join(p, "manifest.yaml")):
            return p
    return None

def main():
    if len(sys.argv) < 2:
        print("사용법: harness-test.py <하네스id> [키트경로]"); sys.exit(2)
    hid = sys.argv[1]
    kit = find_kit(hid, sys.argv[2] if len(sys.argv) > 2 else None)
    if not kit:
        print(f"❌ 하네스를 찾을 수 없음: {hid}"); sys.exit(2)

    manifest = yaml.safe_load(open(os.path.join(kit, "manifest.yaml"), encoding="utf-8"))
    gate_runner = {g["id"]: g["runner"] for g in (manifest.get("gates") or [])}

    cases_path = os.path.join(kit, "tests", "cases.yaml")
    if not os.path.isfile(cases_path):
        print(f"❌ 테스트 케이스가 없음: {cases_path}")
        print("   tests/cases.yaml 을 만들고 좋은/나쁜 예시를 fixtures/ 에 넣으세요.")
        sys.exit(2)
    spec = yaml.safe_load(open(cases_path, encoding="utf-8"))
    cases = spec.get("cases", [])

    print(f"하네스 자가진단: {hid}  (케이스 {len(cases)}개)\n")
    ok = bad = 0
    for c in cases:
        gate = c["gate"]
        runner = gate_runner.get(gate)
        if not runner:
            print(f"  ❌ [{c['name']}] manifest 에 게이트 '{gate}' 없음"); bad += 1; continue
        runner_path = os.path.join(kit, runner)
        inps = c.get("inputs") or [c["input"]]
        try:
            proc = subprocess.run(["bash", runner_path, *map(str, inps)],
                                  capture_output=True, text=True, timeout=60, cwd=kit)
            actual = "pass" if proc.returncode == 0 else "fail"
        except Exception as e:
            print(f"  ❌ [{c['name']}] 실행오류: {e}"); bad += 1; continue
        expect = c.get("expect", "pass")
        if actual == expect:
            sign = "✅" if expect == "pass" else "✅(정상 차단)"
            print(f"  {sign}  {c['name']}   [{gate}: {actual}]")
            ok += 1
        else:
            print(f"  ❌  {c['name']}   기대={expect} 인데 실제={actual}   [{gate}]")
            bad += 1

    print(f"\n===== 결과 =====")
    print(f"  통과 {ok} · 실패 {bad}  (총 {len(cases)})")
    if bad == 0:
        print("  🎉 이 하네스는 좋은 입력을 통과시키고, 나쁜 입력을 제대로 막습니다.")
    else:
        print("  ⚠️  게이트가 기대대로 동작하지 않는 케이스가 있습니다. 위 ❌ 를 확인하세요.")
    sys.exit(1 if bad else 0)

if __name__ == "__main__":
    main()
