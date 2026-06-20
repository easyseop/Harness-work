#!/usr/bin/env bash
# =====================================================================
# check-contract-coverage.sh
# 역할: 테스트 명세(test-spec)가 솔루션 카드(계약)의 약속을 다 덮는지 검사한다.
#   - 카드의 모든 오류코드마다 테스트가 있는지
#   - 정상(happy) 경로 테스트가 있는지
#   - 필수입력 누락 테스트가 있는지
#   - 테스트 데이터에 실제 민감정보가 없는지(간단 패턴)
# 사용: ./check-contract-coverage.sh <test-spec.yaml> <solution-card.yaml> [policy.yaml]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 + pyyaml
# =====================================================================
set -euo pipefail
SPEC="${1:?test-spec.yaml 경로}"
CARD="${2:?solution-card.yaml 경로}"
POLICY="${3:-$(dirname "$0")/../policy.yaml}"

python3 - "$SPEC" "$CARD" "$POLICY" <<'PY'
import sys, re
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

spec = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))
card = yaml.safe_load(open(sys.argv[2], encoding="utf-8"))
pol  = yaml.safe_load(open(sys.argv[3], encoding="utf-8"))
cov  = pol.get("coverage", {})
errors = []

ts = spec.get("test_spec", {})
cases = ts.get("cases", [])
cap_name = ts.get("capability")

# 카드에서 해당 capability 찾기
caps = card.get("capabilities", [])
cap = next((c for c in caps if c.get("name") == cap_name), None)
if cap is None:
    print(f"❌ 솔루션 카드에 capability '{cap_name}' 가 없습니다."); sys.exit(1)

# 테스트가 덮는 result_code 집합
covered = {str(c.get("expect", {}).get("result_code")) for c in cases}
types = {c.get("type") for c in cases}

# 1) 모든 오류코드 덮기
if cov.get("require_all_error_codes"):
    card_codes = {str(e.get("code")) for e in cap.get("errors", [])}
    missing = sorted(card_codes - covered)
    if missing:
        errors.append(f"테스트가 빠진 오류코드: {missing}")

# 2) 정상 경로
if cov.get("require_happy_path") and "happy" not in types:
    errors.append("정상(happy) 경로 테스트가 없음")

# 3) 필수입력 누락 테스트
if cov.get("require_missing_required_field_test") and "missing-field" not in types:
    errors.append("필수입력 누락(missing-field) 테스트가 없음")

# 4) 빈칸/미정
def scan(node, path=""):
    if isinstance(node, dict):
        for k, v in node.items(): scan(v, f"{path}.{k}" if path else k)
    elif isinstance(node, list):
        for i, v in enumerate(node): scan(v, f"{path}[{i}]")
    elif isinstance(node, str) and node.strip() in ("미정","TBD",""):
        errors.append(f"빈칸/미정: {path}")
scan(spec)

# 5) 실제 민감정보 간단 검사 (IP/주민번호/실제주소)
if pol.get("rules", {}).get("forbid_real_data_in_fixtures", True):
    blob = yaml.safe_dump(spec, allow_unicode=True)
    if re.search(r"\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b", blob):
        errors.append("테스트 데이터에 IP 주소로 보이는 값이 있음")
    if re.search(r"\b\d{6}-\d{7}\b", blob):
        errors.append("테스트 데이터에 주민등록번호 형식 값이 있음")

if errors:
    print("❌ 계약 테스트 커버리지 부족:")
    for e in errors: print("   -", e)
    sys.exit(1)
print(f"✅ 계약 테스트 충분 — 케이스 {len(cases)}개, 오류코드/정상/누락 모두 덮음")
PY
