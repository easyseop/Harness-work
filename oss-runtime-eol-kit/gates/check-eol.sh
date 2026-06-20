#!/usr/bin/env bash
# =====================================================================
# check-eol.sh
# 역할: 쓰는 런타임이 수명종료(EOL)되었는지, 임박했는지 검사한다.
#   - 이미 EOL 이면 막음(block_if_eol)
#   - EOL 까지 warn_within_days 보다 적게 남으면 경고(반입은 가능)
# 사용: ./check-eol.sh <components.yaml> [policy.yaml] [기준일자YYYY-MM-DD]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 + pyyaml
# =====================================================================
set -euo pipefail
COMP="${1:?components.yaml 경로}"
POLICY="${2:-$(dirname "$0")/../policy.yaml}"
TODAY="${3:-$(date +%F)}"

python3 - "$COMP" "$POLICY" "$TODAY" <<'PY'
import sys, datetime
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

c = yaml.safe_load(open(sys.argv[1], encoding="utf-8")).get("components", {})
ep = yaml.safe_load(open(sys.argv[2], encoding="utf-8")).get("eol", {})
today = datetime.date.fromisoformat(sys.argv[3])

table = ep.get("runtimes", {}) or {}
block_if_eol = ep.get("block_if_eol", True)
warn_days = ep.get("warn_within_days", 180)

errors, warns = [], []
for rt in c.get("runtimes", []) or []:
    key = f"{rt.get('name')}@{rt.get('version')}"
    eol = table.get(key)
    if not eol:
        warns.append(f"{key}: EOL 날짜표에 없음 — policy.yaml 에 추가 권장")
        continue
    ed = datetime.date.fromisoformat(str(eol))
    days = (ed - today).days
    if days < 0 and block_if_eol:
        errors.append(f"{key}: 이미 수명종료(EOL {eol}) — 업그레이드 필요")
    elif 0 <= days <= warn_days:
        warns.append(f"{key}: EOL {eol} ({days}일 남음) — 교체 계획 권고")

for w in warns: print("⚠️ ", w)
if errors:
    print("❌ EOL 검사 실패:")
    for e in errors: print("   -", e)
    sys.exit(1)
print("✅ 모든 런타임이 수명 내 (EOL 통과)")
PY
