#!/usr/bin/env bash
# =====================================================================
# check-data-values.sh
# 역할: 실제 데이터(CSV) 값이 계약서의 컬럼 기준을 지키는지 검사한다.
#       - type: date8   → 값이 유효한 YYYYMMDD(실제 달력 날짜)여야 함
#       - valid_values  → 값이 그 목록(인스턴스 유효식별자) 안이어야 함
#       단, dataset.standard 가 true(표준 DB/테이블)일 때만 강제한다.
#       비표준이면 검사를 건너뛴다(통과).
# 사용: ./check-data-values.sh <data-contract.yaml> <data.csv> [policy.yaml]
# 통과: exit 0  /  위반: exit 1
# 요구: python3 + pyyaml
# =====================================================================
set -euo pipefail
CONTRACT="${1:-data-contract.yaml}"
DATA="${2:?사용법: check-data-values.sh <contract.yaml> <data.csv> [policy.yaml]}"
POLICY="${3:-$(dirname "$0")/../policy.yaml}"

python3 - "$CONTRACT" "$DATA" "$POLICY" <<'PY'
import sys, csv, datetime
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

contract_path, data_path, policy_path = sys.argv[1], sys.argv[2], sys.argv[3]
c = yaml.safe_load(open(contract_path, encoding="utf-8"))
p = yaml.safe_load(open(policy_path, encoding="utf-8"))
ds = c.get("dataset", {})
vr = p.get("value_rules", {})
date8_type = vr.get("date8_type", "date8")
enforce_vv = vr.get("enforce_valid_values", True)

# 0) 표준/비표준 판정 — 비표준이면 값 검사 건너뜀
if not ds.get("standard", False):
    print(f"⏭️  '{ds.get('name','?')}' 은(는) 비표준 테이블 → 값 검사 건너뜀 (통과)")
    sys.exit(0)

# 컬럼별 규칙 모으기
cols = {col["name"]: col for col in (c.get("columns") or []) if col.get("name")}

def is_valid_date8(v):
    v = v.strip()
    if len(v) != 8 or not v.isdigit():
        return False
    try:
        datetime.datetime.strptime(v, "%Y%m%d"); return True
    except ValueError:
        return False

errors = []
with open(data_path, newline="", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    # 데이터에 있는데 계약서에 없는 컬럼 경고용
    missing_in_contract = [h for h in (reader.fieldnames or []) if h not in cols]
    for rownum, row in enumerate(reader, start=2):  # 2 = 헤더 다음 첫 행
        for cname, col in cols.items():
            if cname not in row:
                continue
            raw = (row[cname] or "").strip()
            nullable = col.get("nullable", True)
            if raw == "":
                if not nullable:
                    errors.append(f"{rownum}행 {cname}: 값이 비었음(nullable=false)")
                continue
            # 1) 년월일8 검사
            if col.get("type") == date8_type and not is_valid_date8(raw):
                errors.append(f"{rownum}행 {cname}: '{raw}' 은(는) 유효한 YYYYMMDD 가 아님")
            # 2) 인스턴스 유효식별자 검사
            vv = col.get("valid_values")
            if enforce_vv and vv is not None:
                allowed = {str(x) for x in vv}
                if raw not in allowed:
                    errors.append(f"{rownum}행 {cname}: '{raw}' 은(는) 유효식별자 {vv} 에 없음")

if missing_in_contract:
    print(f"ℹ️  계약서에 정의되지 않은 컬럼(검사 안 함): {missing_in_contract}")

if errors:
    print(f"❌ 표준 테이블 '{ds.get('name')}' 값 검사 실패 ({len(errors)}건):")
    for e in errors[:50]:
        print("   -", e)
    if len(errors) > 50:
        print(f"   ... 외 {len(errors)-50}건")
    sys.exit(1)
print(f"✅ 표준 테이블 '{ds.get('name')}' 값 검사 통과 — 모든 값이 기준을 지킴")
PY
