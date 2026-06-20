#!/usr/bin/env bash
# =====================================================================
# check-allowed-tech-stack.sh
# 역할: 프로젝트가 고른 스택(프레임워크·배포단위·배포환경·반입방식)이
#       policy.yaml 의 허용 목록 안에 있는지 검사한다.
# 사용: ./check-allowed-tech-stack.sh <profile.json> [policy.yaml]
# 통과: exit 0  /  실패: exit 1  (단, 허용목록 밖이면 waiver 필요)
# 요구: python3 + pyyaml
#       (pyyaml 없으면: pip install pyyaml  / 내부망이면 담당자에게 문의)
# =====================================================================
set -euo pipefail

PROFILE="${1:-profile.json}"
POLICY="${2:-$(dirname "$0")/../policy.yaml}"

python3 - "$PROFILE" "$POLICY" <<'PY'
import json, sys
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없어 policy.yaml 을 읽을 수 없습니다.")
    print("    설치: pip install pyyaml  (내부망이면 담당 개발자에게 문의)")
    sys.exit(2)

profile_path, policy_path = sys.argv[1], sys.argv[2]
with open(profile_path, encoding="utf-8") as f:
    profile = json.load(f)
with open(policy_path, encoding="utf-8") as f:
    policy = yaml.safe_load(f)

allowed = policy.get("allowed_tech_stack", {})
errors = []

def check(label, value, allowed_list):
    if value in ("TBD", "미정", None):
        return  # 빈칸은 다른 게이트가 잡음
    if allowed_list and value not in allowed_list:
        errors.append(f"{label}: '{value}' 는 허용목록에 없음 (허용: {allowed_list})")

대상 = profile.get("구현_대상_정보", {})
환경 = profile.get("실행환경_정보", {})

check("프레임워크", 대상.get("프레임워크"), allowed.get("frameworks"))
check("배포_단위", 대상.get("배포_단위"), allowed.get("deploy_units"))
check("배포_환경", 환경.get("배포_환경"), allowed.get("deploy_targets"))
check("반입_방식", profile.get("반입_방식"), policy.get("allowed_import_methods"))

if errors:
    print("❌ 허용되지 않은 스택이 있습니다 (예외 승인 waiver 필요):")
    for e in errors:
        print("   -", e)
    sys.exit(1)

print("✅ 모든 스택이 허용 목록 안에 있음")
PY
