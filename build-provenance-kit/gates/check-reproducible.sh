#!/usr/bin/env bash
# =====================================================================
# check-reproducible.sh
# 역할: 외부망 빌드 결과 해시와 내부망 재빌드 해시가 같은지 검사한다.
#       같으면 "같은 입력 → 같은 결과"(재현성)가 확인된 것.
# 사용: ./check-reproducible.sh <provenance.yaml> [policy.yaml]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 + pyyaml
# 참고: 내부망 재빌드 전이라 rebuilt_output_hash 가 비어 있으면 '아직 미확인'으로 통과 보류(0).
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
rep = p.get("reproducible", {})

out = pv.get("output_hash")
rebuilt = (pv.get("reproduce", {}) or {}).get("rebuilt_output_hash")
EMPTY = (None, "", "미정", "TBD")

if rebuilt in EMPTY:
    print("ℹ️  내부망 재빌드 해시가 아직 없음 — reproduce 단계에서 채운 뒤 다시 검사하세요.")
    sys.exit(0)

if rep.get("require_match") and out != rebuilt:
    print("❌ 재현성 실패 — 외부망 빌드와 내부망 재빌드 결과가 다릅니다:")
    print(f"   - 외부망 output_hash      : {out}")
    print(f"   - 내부망 rebuilt_output_hash: {rebuilt}")
    print("   (잠금파일/빌드환경 차이를 확인하세요)")
    sys.exit(1)
print("✅ 재현성 확인 — 외부망 빌드와 내부망 재빌드 결과가 동일")
PY
