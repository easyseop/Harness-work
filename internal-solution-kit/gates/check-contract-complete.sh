#!/usr/bin/env bash
# =====================================================================
# check-contract-complete.sh
# 역할: 솔루션 카드에 빈칸(미정/TBD)이 없는지, 필수 항목이 다 있는지 검사한다.
# 사용: ./check-contract-complete.sh <solution-card.yaml> [solution-card.schema.json]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 + pyyaml  (없으면: pip install pyyaml)
# =====================================================================
set -euo pipefail
CARD="${1:-solution-card.yaml}"
SCHEMA="${2:-$(dirname "$0")/../solution-card.schema.json}"

python3 - "$CARD" "$SCHEMA" <<'PY'
import json, sys
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없어 카드를 읽을 수 없습니다. 설치: pip install pyyaml")
    sys.exit(2)

card_path, schema_path = sys.argv[1], sys.argv[2]
with open(card_path, encoding="utf-8") as f:
    card = yaml.safe_load(f)

errors = []

# 1) 미정/TBD 가 남은 칸 찾기
def scan(node, path=""):
    if isinstance(node, dict):
        for k, v in node.items():
            scan(v, f"{path}.{k}" if path else k)
    elif isinstance(node, list):
        for i, v in enumerate(node):
            scan(v, f"{path}[{i}]")
    elif isinstance(node, str) and node.strip() in ("미정", "TBD", ""):
        errors.append(f"빈칸/미정: {path}")

scan(card)

# 2) 스키마의 필수 최상위 항목 확인 (가벼운 검사)
try:
    with open(schema_path, encoding="utf-8") as f:
        schema = json.load(f)
    for req in schema.get("required", []):
        if req not in (card or {}):
            errors.append(f"필수 항목 누락: {req}")
except FileNotFoundError:
    pass

if errors:
    print("❌ 카드가 완성되지 않았습니다:")
    for e in errors:
        print("   -", e)
    sys.exit(1)

print("✅ 카드 완성 — 빈칸/누락 없음")
PY
