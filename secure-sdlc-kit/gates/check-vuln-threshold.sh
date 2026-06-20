#!/usr/bin/env bash
# =====================================================================
# check-vuln-threshold.sh
# 역할: 의존성 취약점이 허용 심각도 기준을 넘는지 검사한다.
#   - max_allowed_severity 보다 높은 취약점이 있으면 막음
#   - block_high_and_critical 이 켜져 있으면 high/critical 0건 강제
# 사용: ./check-vuln-threshold.sh <scan-report.json> [policy.yaml]
# 통과: exit 0  /  실패: exit 1
# 요구: python3
# =====================================================================
set -euo pipefail
REPORT="${1:?scan-report.json 경로}"
POLICY="${2:-$(dirname "$0")/../policy.yaml}"

python3 - "$REPORT" "$POLICY" <<'PY'
import sys, json
report = json.load(open(sys.argv[1], encoding="utf-8"))
try:
    import yaml
    pol = yaml.safe_load(open(sys.argv[2], encoding="utf-8"))
except Exception:
    pol = {}

ORDER = ["none", "low", "medium", "high", "critical"]
def rank(s): return ORDER.index(s) if s in ORDER else len(ORDER)

vcfg = (pol.get("vulnerability") or {}) if pol else {}
max_allowed = vcfg.get("max_allowed_severity", "medium")
block_hc = vcfg.get("block_high_and_critical", True)

vulns = report.get("vulnerabilities", []) or []
over = []
for v in vulns:
    sev = (v.get("severity") or "").lower()
    if rank(sev) > rank(max_allowed):
        over.append(v)
    elif block_hc and sev in ("high", "critical"):
        over.append(v)

if over:
    print(f"❌ 허용 심각도({max_allowed}) 를 넘는 취약점 {len(over)}건 (예외는 만료 있는 waiver 로만):")
    for v in over[:30]:
        print(f"   - [{v.get('severity')}] {v.get('id')}  {v.get('component')}  → 수정버전: {v.get('fixed_in','?')}")
    sys.exit(1)
print(f"✅ 취약점 기준 통과 — 전체 {len(vulns)}건 모두 {max_allowed} 이하")
PY
