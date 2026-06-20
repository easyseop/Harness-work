#!/usr/bin/env bash
# =====================================================================
# check-metadata-complete.sh
# 역할: 필수 메타데이터가 다 있는지, 등급이 허용목록 안인지, lineage 가 있는지,
#       빈칸(미정/TBD)이 없는지 검사한다.
# 사용: ./check-metadata-complete.sh <data-contract.yaml> [policy.yaml]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 + pyyaml
# =====================================================================
set -euo pipefail
CONTRACT="${1:-data-contract.yaml}"
POLICY="${2:-$(dirname "$0")/../policy.yaml}"

python3 - "$CONTRACT" "$POLICY" <<'PY'
import sys
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

c = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))
p = yaml.safe_load(open(sys.argv[2], encoding="utf-8"))
errors = []

# 1) 빈칸/미정 검사
def scan(node, path=""):
    if isinstance(node, dict):
        for k, v in node.items(): scan(v, f"{path}.{k}" if path else k)
    elif isinstance(node, list):
        for i, v in enumerate(node): scan(v, f"{path}[{i}]")
    elif isinstance(node, str) and node.strip() in ("미정", "TBD", ""):
        errors.append(f"빈칸/미정: {path}")
scan(c)

ds = c.get("dataset", {})

# 2) 필수 메타데이터
for req in p.get("required_metadata", []):
    if req not in ds or ds.get(req) in (None, "", "TBD", "미정"):
        errors.append(f"필수 메타데이터 누락: {req}")

# 3) 등급이 허용목록 안인지
allowed = p.get("allowed_classifications", [])
cls = ds.get("classification")
if allowed and cls not in allowed and cls not in ("TBD", "미정"):
    errors.append(f"데이터 등급 '{cls}' 은(는) 허용목록에 없음 (허용: {allowed})")

# 4) lineage 요구
if p.get("require_lineage"):
    lin = c.get("lineage", {})
    if not lin.get("inputs") and not lin.get("outputs"):
        errors.append("lineage(흐름)가 비어 있음 — 입력/출력 중 최소 하나는 적어야 함")

if errors:
    print("❌ 메타데이터가 완성되지 않았습니다:")
    for e in errors: print("   -", e)
    sys.exit(1)
print("✅ 메타데이터 완성 — 빈칸/누락/등급오류 없음")
PY
