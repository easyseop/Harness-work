#!/usr/bin/env bash
# =====================================================================
# check-roles-and-waivers.sh   ★ 반입 마지막 관문 (우회 불가)
# 역할: 역할 분리(만든 사람 ≠ 승인한 사람)와 예외 승인(waiver) 규칙을 검사한다.
#   - developer / verifier / approver 가 다 있는지
#   - developer 와 approver 가 서로 다른지 (INV-7)
#   - 모든 waiver 에 필수 항목이 있고, 만료되지 않았는지 (INV-6)
# 사용: ./check-roles-and-waivers.sh <bundle-manifest.yaml> [policy.yaml] [기준일자YYYY-MM-DD]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 + pyyaml
# =====================================================================
set -euo pipefail
BUNDLE="${1:?bundle-manifest.yaml 경로}"
POLICY="${2:-$(dirname "$0")/../policy.yaml}"
TODAY="${3:-$(date +%F)}"

python3 - "$BUNDLE" "$POLICY" "$TODAY" <<'PY'
import sys, datetime
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

b = yaml.safe_load(open(sys.argv[1], encoding="utf-8")).get("bundle", {})
p = yaml.safe_load(open(sys.argv[2], encoding="utf-8"))
today = datetime.date.fromisoformat(sys.argv[3])
errors = []

# --- 역할 분리 ---
rs = p.get("role_separation", {})
att = b.get("attestation", {}) or {}
if rs.get("required"):
    for role in rs.get("required_roles", []):
        v = att.get(role)
        if not v or str(v).strip() in ("미정","TBD",""):
            errors.append(f"역할 누락: {role}")
    dev, app = att.get("developer"), att.get("approver")
    if rs.get("developer_must_differ_from_approver") and dev and app and dev == app:
        errors.append(f"역할 분리 위반: 만든 사람과 승인자가 같음 ('{dev}')")
    if rs.get("verifier_should_differ"):
        ver = att.get("verifier")
        if ver and ver == dev:
            errors.append(f"주의: 검사자와 만든 사람이 같음 ('{ver}')")

# --- 예외 승인(waiver) ---
wcfg = p.get("waivers", {})
waivers = b.get("waivers", []) or []
for i, w in enumerate(waivers):
    tag = w.get("gate", f"[{i}]")
    for f in wcfg.get("required_fields", []):
        if not w.get(f) or str(w.get(f)).strip() in ("미정","TBD",""):
            errors.append(f"waiver({tag}) 필수항목 누락: {f}")
    exp = w.get("expires_on")
    if wcfg.get("require_expiry") and not exp:
        errors.append(f"waiver({tag}) 만료일(expires_on) 없음 — 무기한 우회 금지")
    elif exp:
        try:
            ed = datetime.date.fromisoformat(str(exp))
            if wcfg.get("block_if_expired") and ed < today:
                errors.append(f"waiver({tag}) 만료됨: {exp} (기준일 {today})")
        except ValueError:
            errors.append(f"waiver({tag}) 만료일 형식 오류: {exp} (YYYY-MM-DD)")

if errors:
    print("❌ 역할 분리/예외 승인 규칙 위반:")
    for e in errors: print("   -", e)
    sys.exit(1)
msg = "✅ 역할 분리 정상(만든 사람 ≠ 승인자)"
msg += f", 예외 승인 {len(waivers)}건 모두 유효" if waivers else ", 예외 없음"
print(msg)
PY
