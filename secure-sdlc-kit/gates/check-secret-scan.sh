#!/usr/bin/env bash
# =====================================================================
# check-secret-scan.sh   ★ 보안 핵심 (우회 불가)
# 역할: 보안 스캔 보고서에 비밀값(secret) 발견이 있으면 막는다.
#       또 필수 스캔(secret_scan 등)이 실제로 돌았는지 확인한다.
# 사용: ./check-secret-scan.sh <scan-report.json> [policy.yaml]
# 통과: exit 0  /  실패: exit 1
# 요구: python3 (표준 라이브러리만)
# =====================================================================
set -euo pipefail
REPORT="${1:?scan-report.json 경로}"
POLICY="${2:-$(dirname "$0")/../policy.yaml}"

python3 - "$REPORT" "$POLICY" <<'PY'
import sys, json
report = json.load(open(sys.argv[1], encoding="utf-8"))
# policy 는 yaml 이지만 필요한 값만 간단히 읽기 위해 yaml 시도, 없으면 기본값
try:
    import yaml
    pol = yaml.safe_load(open(sys.argv[2], encoding="utf-8"))
except Exception:
    pol = {}
errors = []

required = (pol.get("required_scans") or ["secret_scan", "dependency_scan"])
run = set(report.get("scans_run", []))
for s in required:
    if s not in run:
        errors.append(f"필수 스캔이 실행되지 않음: {s}")

ss = pol.get("secret_scan", {}) if pol else {}
block_any = ss.get("block_if_any", True)
findings = report.get("secret_findings", []) or []
if block_any and findings:
    errors.append(f"비밀값 {len(findings)}건 발견 — 즉시 제거 필요:")
    for f in findings[:20]:
        errors.append(f"   · {f.get('file')}:{f.get('line')} ({f.get('rule')})")

if errors:
    print("❌ 비밀값 스캔 실패:")
    for e in errors: print("   -", e if not e.startswith("   ") else e)
    sys.exit(1)
print("✅ 비밀값 0건, 필수 스캔 실행 확인")
PY
