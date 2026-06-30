#!/usr/bin/env bash
# =====================================================================
# run-golden.sh · 골든 테스트
#   각 입력을 게이트에 돌려 "실제결과"를 만들고, "예상결과(*.expected.json)"와 비교한다.
#   (generated_at 은 매번 달라지므로 비교에서 제외)
# 사용: bash tests/run-golden.sh
# 통과: exit 0 / 하나라도 다르면 exit 1
# 요구: python3 + pyyaml
# =====================================================================
set -u
KIT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$KIT"
pass=0; fail=0

cmp_case() {  # cmp_case <gate> <input> <expected.json>
  local gate="$1" inp="$2" exp="$3" act; act="$(mktemp)"
  DA_OUT="$act" bash "gates/$gate.sh" "$inp" >/dev/null 2>&1
  python3 - "$act" "$exp" <<'PY'
import sys, json
def norm(p):
    d = json.load(open(p, encoding="utf-8")); d.pop("generated_at", None); return d
a, e = norm(sys.argv[1]), norm(sys.argv[2])
if a == e:
    sys.exit(0)
print(f"     상태: 예상={e.get('status')} / 실제={a.get('status')}")
ea = [f["message"] for f in e["findings"]]; aa = [f["message"] for f in a["findings"]]
for m in ea:
    if m not in aa: print("     - 예상엔 있으나 실제에 없음:", m)
for m in aa:
    if m not in ea: print("     + 실제에만 있음:", m)
sys.exit(1)
PY
  if [ $? -eq 0 ]; then echo "  ✅ PASS  $gate  ←  $inp"; pass=$((pass+1))
  else                  echo "  ❌ FAIL  $gate  ←  $inp"; fail=$((fail+1)); fi
  rm -f "$act"
}

echo "== da-review 골든 테스트 =="
cmp_case check-physical      tests/golden/db-good.input.yaml   tests/golden/db-good.physical.expected.json
cmp_case check-attribute     tests/golden/db-good.input.yaml   tests/golden/db-good.attribute.expected.json
cmp_case check-physical      tests/golden/db-bad.input.yaml    tests/golden/db-bad.physical.expected.json
cmp_case check-attribute     tests/golden/db-bad.input.yaml    tests/golden/db-bad.attribute.expected.json
cmp_case check-physical      tests/golden/nested-good.input.yaml tests/golden/nested-good.physical.expected.json  # 중첩 도메인(명50/고객명42 둘다 pass)
cmp_case check-instance-code tests/golden/inst-good.input.yaml tests/golden/inst-good.expected.json
cmp_case check-instance-code tests/golden/inst-bad.input.yaml  tests/golden/inst-bad.expected.json
echo; echo "결과: PASS $pass · FAIL $fail"
[ "$fail" -eq 0 ]
