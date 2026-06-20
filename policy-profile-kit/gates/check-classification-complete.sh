#!/usr/bin/env bash
# =====================================================================
# check-classification-complete.sh
# 역할: 프로젝트 분류 결과(profile.json)에 빈칸이 남았는지 검사한다.
#       - 형식이 스키마에 맞는지
#       - '미정' 또는 'TBD' 가 남아 있지 않은지
# 사용: ./check-classification-complete.sh <profile.json> [profile.schema.json]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 (대부분 기본 설치됨)
# =====================================================================
set -euo pipefail

PROFILE="${1:-profile.json}"
SCHEMA="${2:-$(dirname "$0")/../profile.schema.json}"

if [[ ! -f "$PROFILE" ]]; then
  echo "❌ 분류 결과 파일을 찾을 수 없습니다: $PROFILE"
  exit 1
fi

python3 - "$PROFILE" "$SCHEMA" <<'PY'
import json, sys

profile_path, schema_path = sys.argv[1], sys.argv[2]
with open(profile_path, encoding="utf-8") as f:
    profile = json.load(f)

errors = []

# 1) '미정' / 'TBD' 가 남은 칸 찾기 (재귀적으로 전체 탐색)
def scan(node, path=""):
    if isinstance(node, dict):
        for k, v in node.items():
            scan(v, f"{path}.{k}" if path else k)
    elif isinstance(node, list):
        for i, v in enumerate(node):
            scan(v, f"{path}[{i}]")
    elif isinstance(node, str) and node.strip() in ("미정", "TBD", ""):
        errors.append(f"빈칸/미정 값: {path} = '{node}'")

scan(profile)

# 2) 스키마의 필수 최상위 항목이 있는지 (가벼운 검사 — 전체 검증은 별도 도구로)
try:
    with open(schema_path, encoding="utf-8") as f:
        schema = json.load(f)
    for req in schema.get("required", []):
        if req not in profile:
            errors.append(f"필수 항목 누락: {req}")
except FileNotFoundError:
    pass

if errors:
    print("❌ 분류가 완료되지 않았습니다:")
    for e in errors:
        print("   -", e)
    sys.exit(1)

print("✅ 분류 완료 — 빈칸/미정 없음")
PY
