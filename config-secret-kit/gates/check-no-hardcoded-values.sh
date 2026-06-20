#!/usr/bin/env bash
# =====================================================================
# check-no-hardcoded-values.sh   ★ 보안 핵심 게이트 (우회 불가)
# 역할: 외부망 코드/설정 파일에 실제 값(IP·URL·비밀번호·개인키)이
#       직접 박혀 있지 않은지 검사한다.
#       실제 값은 빈 자리 ${...} 로만 적혀 있어야 한다.
# 사용: ./check-no-hardcoded-values.sh <검사할_경로> [policy.yaml]
#       (경로는 파일 1개 또는 폴더. 폴더면 안의 텍스트 파일을 훑는다)
# 통과: exit 0  /  실패: exit 1
# 요구: python3 + pyyaml
# =====================================================================
set -euo pipefail
TARGET="${1:?검사할 파일/폴더 경로를 주세요}"
POLICY="${2:-$(dirname "$0")/../policy.yaml}"

python3 - "$TARGET" "$POLICY" <<'PY'
import sys, os, re
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

target, policy_path = sys.argv[1], sys.argv[2]
p = yaml.safe_load(open(policy_path, encoding="utf-8"))
patterns = [(x["name"], re.compile(x["regex"])) for x in p.get("forbidden_real_value_patterns", [])]

# 빈 자리 형식: 매칭된 실제값이 ${...} 안이면 통과로 본다
ph = p.get("placeholder", {}).get("pattern", r"\$\{[A-Z][A-Z0-9_]*\}")
ph_re = re.compile(ph)

SKIP_DIRS = {".git", "node_modules", "__pycache__", ".venv", "venv", "dist", "build"}
TEXT_EXT = {".py",".js",".ts",".java",".go",".rb",".sh",".yaml",".yml",".json",
            ".xml",".properties",".env",".conf",".ini",".toml",".txt",".md",".sql",".tf"}

def files(path):
    if os.path.isfile(path):
        yield path; return
    for root, dirs, fs in os.walk(path):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in fs:
            if os.path.splitext(f)[1].lower() in TEXT_EXT:
                yield os.path.join(root, f)

hits = []
for fp in files(target):
    try:
        for n, line in enumerate(open(fp, encoding="utf-8", errors="ignore"), 1):
            # 빈 자리는 가린 뒤 검사 → ${MESSENGER_HOST} 는 잡지 않음
            masked = ph_re.sub("__PLACEHOLDER__", line)
            for name, rx in patterns:
                if rx.search(masked):
                    hits.append((fp, n, name, line.strip()[:80]))
    except Exception:
        pass

if hits:
    print("❌ 외부망에 두면 안 되는 '실제 값'이 코드/설정에 박혀 있습니다:")
    print("   (실제 값 대신 빈 자리 ${이름} 로 바꾸고 binding 목록에 선언하세요)")
    for fp, n, name, txt in hits[:50]:
        print(f"   - {fp}:{n}  [{name}]  {txt}")
    if len(hits) > 50:
        print(f"   ... 외 {len(hits)-50}건")
    sys.exit(1)
print("✅ 실제 값 박힘 없음 — 빈 자리(placeholder)로만 처리됨")
PY
