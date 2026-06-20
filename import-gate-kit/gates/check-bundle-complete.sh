#!/usr/bin/env bash
# =====================================================================
# check-bundle-complete.sh   ★ 반입 마지막 관문 (우회 불가)
# 역할: 반입 묶음에 필요한 구성요소가 다 있고, 필수 증거가 모두 통과(passed)인지 검사한다.
# 사용: ./check-bundle-complete.sh <bundle-manifest.yaml> [policy.yaml]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 + pyyaml
# =====================================================================
set -euo pipefail
BUNDLE="${1:?bundle-manifest.yaml 경로}"
POLICY="${2:-$(dirname "$0")/../policy.yaml}"

python3 - "$BUNDLE" "$POLICY" <<'PY'
import sys
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

b = yaml.safe_load(open(sys.argv[1], encoding="utf-8")).get("bundle", {})
p = yaml.safe_load(open(sys.argv[2], encoding="utf-8"))
errors = []

# 1) 빈칸/미정
def scan(node, path=""):
    if isinstance(node, dict):
        for k, v in node.items(): scan(v, f"{path}.{k}" if path else k)
    elif isinstance(node, list):
        for i, v in enumerate(node): scan(v, f"{path}[{i}]")
    elif isinstance(node, str) and node.strip() in ("미정","TBD",""):
        errors.append(f"빈칸/미정: {path}")
scan(b)

items = b.get("items", {})
evidence = b.get("evidence", [])

# 2) 필수 구성요소 존재 (attestation/waivers 는 별도 키)
present_keys = set(items.keys())
have_attestation = bool(b.get("attestation"))
have_waivers = "waivers" in b
for req in p.get("required_bundle_items", []):
    if req == "attestation":
        if not have_attestation: errors.append("구성요소 누락: attestation")
    elif req == "waivers":
        if not have_waivers: errors.append("구성요소 누락: waivers (없으면 빈 목록 [] 로)")
    elif req == "evidence":
        if not evidence: errors.append("구성요소 누락: evidence(증거)가 비어 있음")
    else:
        v = items.get(req)
        if req not in present_keys or v in (None, "", "none", "미정", "TBD"):
            errors.append(f"구성요소 누락: {req}")

# 3) 필수 증거가 모두 passed 인지
if p.get("require_all_evidence_passed"):
    for e in evidence:
        if e.get("required") and e.get("status") != "passed":
            errors.append(f"필수 증거 미통과: {e.get('id')} (status={e.get('status')})")

if errors:
    print("❌ 반입 묶음이 완성되지 않았습니다:")
    for e in errors: print("   -", e)
    sys.exit(1)
print(f"✅ 반입 묶음 완성 — 구성요소 갖춤, 필수 증거 {len(evidence)}건 모두 통과")
PY
