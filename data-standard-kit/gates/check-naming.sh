#!/usr/bin/env bash
# =====================================================================
# check-naming.sh
# 역할: 테이블/컬럼 이름이 policy.yaml 의 이름 규칙(정규식)을 따르는지 검사한다.
# 사용: ./check-naming.sh <data-contract.yaml> [policy.yaml]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 + pyyaml
# =====================================================================
set -euo pipefail
CONTRACT="${1:-data-contract.yaml}"
POLICY="${2:-$(dirname "$0")/../policy.yaml}"

python3 - "$CONTRACT" "$POLICY" <<'PY'
import sys, re
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

c = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))
p = yaml.safe_load(open(sys.argv[2], encoding="utf-8"))
naming = p.get("naming", {})
errors = []

ds = c.get("dataset", {})
name = ds.get("name", "")
tpat = naming.get("table_pattern")
if tpat and name not in ("TBD", "미정") and not re.match(tpat, name):
    errors.append(f"테이블 이름 '{name}' 이(가) 규칙에 안 맞음 (규칙: {tpat})")

prefixes = naming.get("table_prefixes") or []
if prefixes and not any(name.startswith(pre) for pre in prefixes):
    errors.append(f"테이블 이름 '{name}' 은(는) 접두사 {prefixes} 중 하나로 시작해야 함")

cpat = naming.get("column_pattern")
for col in c.get("columns", []) or []:
    cn = col.get("name", "")
    if cpat and cn not in ("TBD", "미정") and not re.match(cpat, cn):
        errors.append(f"컬럼 이름 '{cn}' 이(가) 규칙에 안 맞음 (규칙: {cpat})")

if errors:
    print("❌ 이름 규칙 위반:")
    for e in errors: print("   -", e)
    sys.exit(1)
print("✅ 모든 이름이 규칙을 따름")
PY
