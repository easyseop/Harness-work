#!/usr/bin/env bash
# =====================================================================
# check-runbook-complete.sh
# 역할: 배포 안내서에 필수 단계(사전점검/배포/검증/롤백/연락)가 다 있고
#       비어 있지 않은지, 롤백·검증 단계가 실제로 있는지 검사한다.
# 사용: ./check-runbook-complete.sh <runbook.yaml> [policy.yaml]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 + pyyaml
# =====================================================================
set -euo pipefail
RB="${1:?runbook.yaml 경로}"
POLICY="${2:-$(dirname "$0")/../policy.yaml}"

python3 - "$RB" "$POLICY" <<'PY'
import sys
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

rb = yaml.safe_load(open(sys.argv[1], encoding="utf-8")).get("runbook", {})
p  = yaml.safe_load(open(sys.argv[2], encoding="utf-8"))
rules = p.get("rules", {})
errors = []

def is_empty_list(v):
    if not v: return True
    if isinstance(v, list):
        real = [x for x in v if str(x).strip() not in ("미정","TBD","")]
        return len(real) == 0
    return False

for sec in p.get("required_sections", []):
    v = rb.get(sec)
    if v is None:
        errors.append(f"단계 누락: {sec}")
    elif is_empty_list(v):
        errors.append(f"단계 비어있음/미정: {sec}")

if rules.get("require_rollback") and is_empty_list(rb.get("rollback")):
    errors.append("롤백 절차가 비어 있음 — 되돌릴 방법 없는 배포 금지")
if rules.get("require_verify_steps") and is_empty_list(rb.get("verify")):
    errors.append("검증 단계가 비어 있음 — 배포 후 확인 항목 필요")

# 연락처 역할 검사
if rules.get("contacts_role_only"):
    for c in rb.get("contacts", []) or []:
        if not c.get("role") or str(c.get("role")).strip() in ("미정","TBD",""):
            errors.append("연락처에 역할(role)이 비어 있음")

if errors:
    print("❌ 배포 안내서가 완성되지 않았습니다:")
    for e in errors: print("   -", e)
    sys.exit(1)
print("✅ 배포 안내서 완성 — 사전점검/배포/검증/롤백/연락 모두 갖춤")
PY
