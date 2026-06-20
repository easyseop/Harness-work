#!/usr/bin/env bash
# =====================================================================
# check-provenance-complete.sh   ★ (우회 불가)
# 역할: 빌드 출처 필수 항목이 다 있는지, 잠금파일·SBOM 이 갖춰졌는지 검사한다.
# 사용: ./check-provenance-complete.sh <provenance.yaml> [policy.yaml]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 + pyyaml
# =====================================================================
set -euo pipefail
PROV="${1:?provenance.yaml 경로}"
POLICY="${2:-$(dirname "$0")/../policy.yaml}"

python3 - "$PROV" "$POLICY" <<'PY'
import sys
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

pv = yaml.safe_load(open(sys.argv[1], encoding="utf-8")).get("provenance", {})
p  = yaml.safe_load(open(sys.argv[2], encoding="utf-8"))
errors = []
EMPTY = (None, "", "미정", "TBD")

for f in p.get("required_provenance_fields", []):
    if pv.get(f) in EMPTY:
        errors.append(f"출처 항목 누락: {f}")

art = pv.get("artifacts", {}) or {}
ac = p.get("artifacts", {})
if ac.get("require_lockfile") and art.get("lockfile") in EMPTY:
    errors.append("잠금 파일(lockfile) 누락 — 버전 고정 필요")
if ac.get("require_sbom") and art.get("sbom") in EMPTY:
    errors.append("구성요소 목록(SBOM) 누락")

if errors:
    print("❌ 빌드 출처가 완성되지 않았습니다:")
    for e in errors: print("   -", e)
    sys.exit(1)
print("✅ 빌드 출처 완성 — 필수 항목·잠금파일·SBOM 갖춤")
PY
