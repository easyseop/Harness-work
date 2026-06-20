#!/usr/bin/env bash
# =====================================================================
# check-license.sh
# 역할: 라이브러리 라이선스가 허용목록 안인지, 금지목록에 없는지 검사한다.
#   - 금지(denied) 라이선스면 무조건 막음
#   - 허용목록에 없는 라이선스는 policy 의 unknown_action 에 따름(block/warn)
# 사용: ./check-license.sh <components.yaml> [policy.yaml]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 + pyyaml
# =====================================================================
set -euo pipefail
COMP="${1:?components.yaml 경로}"
POLICY="${2:-$(dirname "$0")/../policy.yaml}"

python3 - "$COMP" "$POLICY" <<'PY'
import sys
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

c = yaml.safe_load(open(sys.argv[1], encoding="utf-8")).get("components", {})
lp = yaml.safe_load(open(sys.argv[2], encoding="utf-8")).get("licenses", {})
allowed = set(lp.get("allowed", []))
denied  = set(lp.get("denied", []))
unknown_action = lp.get("unknown_action", "block")

errors, warns = [], []
for lib in c.get("libraries", []) or []:
    name = f"{lib.get('name')} {lib.get('version')}"
    lic = lib.get("license")
    if lic in (None, "", "미정", "TBD"):
        errors.append(f"{name}: 라이선스 미기재")
    elif lic in denied:
        errors.append(f"{name}: 금지 라이선스 '{lic}'")
    elif lic not in allowed:
        if unknown_action == "block":
            errors.append(f"{name}: 허용목록에 없는 라이선스 '{lic}'")
        else:
            warns.append(f"{name}: 미확인 라이선스 '{lic}' (경고)")

for w in warns: print("⚠️ ", w)
if errors:
    print("❌ 라이선스 검사 실패 (예외는 만료 있는 waiver 로만):")
    for e in errors: print("   -", e)
    sys.exit(1)
print("✅ 모든 라이브러리 라이선스가 허용 범위")
PY
