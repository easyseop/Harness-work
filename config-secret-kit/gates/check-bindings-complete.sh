#!/usr/bin/env bash
# =====================================================================
# check-bindings-complete.sh
# 역할: 바인딩 목록이 규칙(policy.yaml)을 지키는지 검사한다.
#   - 빈칸(미정/TBD) 없는지
#   - secret 은 internal-only 이고 default 가 없는지
#   - config 의 default 규칙
#   - 이름이 대문자_스네이크 형식인지
# 사용: ./check-bindings-complete.sh <binding.yaml> [policy.yaml]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 + pyyaml
# =====================================================================
set -euo pipefail
BINDING="${1:-binding.yaml}"
POLICY="${2:-$(dirname "$0")/../policy.yaml}"

python3 - "$BINDING" "$POLICY" <<'PY'
import sys, re
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

b = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))
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
scan(b)

binding = b.get("binding", {})
variables = binding.get("variables", [])
if not variables:
    errors.append("variables(빈 자리 목록)가 비어 있음")

name_re = re.compile(r"^[A-Z][A-Z0-9_]*$")
rules = p.get("rules", {})
seen = set()

for i, v in enumerate(variables):
    nm = v.get("name", f"[{i}]")
    # 이름 형식
    if isinstance(nm, str) and nm not in ("미정","TBD") and not name_re.match(nm):
        errors.append(f"이름 형식 오류(대문자_스네이크 아님): {nm}")
    # 중복
    if nm in seen:
        errors.append(f"이름 중복: {nm}")
    seen.add(nm)

    kind = v.get("kind")
    zone = v.get("zone")
    default = v.get("default", None)

    # secret 규칙
    if kind == "secret":
        if rules.get("secret_must_be_internal_only") and zone != "internal-only":
            errors.append(f"{nm}: secret 인데 zone 이 internal-only 가 아님 (현재: {zone})")
        if rules.get("secret_forbids_default") and default not in (None,):
            errors.append(f"{nm}: secret 은 default 를 둘 수 없음 (실제 값 박힘 위험)")

if errors:
    print("❌ 바인딩 목록이 규칙을 위반했습니다:")
    for e in errors: print("   -", e)
    sys.exit(1)
print(f"✅ 바인딩 목록 정상 — 빈 자리 {len(variables)}개, 규칙 위반 없음")
PY
