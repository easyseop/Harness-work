#!/usr/bin/env bash
# =====================================================================
# check-no-secrets-in-runbook.sh   ★ 보안 핵심 (우회 불가)
# 역할: 배포 안내서에 실제 값(IP·URL·비밀번호/토큰)이 적혀 있지 않은지 검사한다.
#       실제 값은 빈 자리/역할로만 적어야 한다.
# 사용: ./check-no-secrets-in-runbook.sh <runbook.yaml> [policy.yaml]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 + pyyaml
# =====================================================================
set -euo pipefail
RB="${1:?runbook.yaml 경로}"
POLICY="${2:-$(dirname "$0")/../policy.yaml}"

python3 - "$RB" "$POLICY" <<'PY'
import sys, re
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

raw = open(sys.argv[1], encoding="utf-8").read()
p   = yaml.safe_load(open(sys.argv[2], encoding="utf-8"))
patterns = [(x["name"], re.compile(x["regex"])) for x in p.get("forbidden_patterns", [])]

# 빈 자리 ${...} 는 가려서 오탐 방지
masked_lines = []
ph = re.compile(r"\$\{[A-Z][A-Z0-9_]*\}")
for i, line in enumerate(raw.splitlines(), 1):
    masked_lines.append((i, ph.sub("__PLACEHOLDER__", line), line))

hits = []
for i, masked, orig in masked_lines:
    for name, rx in patterns:
        if rx.search(masked):
            hits.append((i, name, orig.strip()[:80]))

if hits:
    print("❌ 배포 안내서에 실제 값(민감정보)이 있습니다 (빈 자리/역할로 바꾸세요):")
    for i, name, txt in hits[:30]:
        print(f"   - {i}행 [{name}]  {txt}")
    sys.exit(1)
print("✅ 안내서에 실제 주소·비밀번호 없음 — 빈 자리/역할로만 작성됨")
PY
