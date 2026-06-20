#!/usr/bin/env bash
# =====================================================================
# check-no-internal-secrets.sh
# 역할: 카드(또는 폴더)에 실제 주소·비밀번호·개인정보가 섞였는지 검사한다.
#       이것은 규칙 5(민감정보 금지)를 자동으로 지키게 하는 가장 중요한 검사다.
# 사용: ./check-no-internal-secrets.sh <파일 또는 폴더>
# 통과: exit 0  /  발견: exit 1   (이 검사는 예외 승인으로 넘길 수 없음)
# 요구: python3
# =====================================================================
set -euo pipefail
TARGET="${1:-.}"

python3 - "$TARGET" <<'PY'
import os, re, sys

target = sys.argv[1]
files = []
if os.path.isdir(target):
    for root, _, fs in os.walk(target):
        for f in fs:
            if f.endswith((".yaml", ".yml", ".json", ".md", ".py", ".java", ".js", ".ts", ".properties", ".env")):
                files.append(os.path.join(root, f))
else:
    files = [target]

# 막을 패턴 (발견되면 실패) — 라벨, 정규식
BLOCK = [
    ("실제 IP 주소",      re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b")),
    ("실제 URL/주소",     re.compile(r"https?://[^\s'\"]+", re.I)),
    ("비밀값 지정",        re.compile(r"\b(password|passwd|pwd|secret|token|api[_-]?key|private[_-]?key)\b\s*[:=]\s*\S+", re.I)),
    ("비밀키 블록",        re.compile(r"-----BEGIN [A-Z ]*PRIVATE KEY-----")),
    ("주민등록번호 형태",   re.compile(r"\b\d{6}[-\s]?[1-4]\d{6}\b")),
]
# 경고만 (참고용) — 길이 긴 숫자(계좌/카드처럼 보일 수 있음)
WARN = [
    ("긴 숫자(계좌/카드 의심)", re.compile(r"\b\d{10,16}\b")),
]
# 예시/설명용으로 허용되는 안전한 표현(오탐 줄이기)
SAFE_HINTS = ("예:", "example", "TBD", "최대", "최소", "0.0", "draft")

errors, warnings = [], []
for path in files:
    try:
        with open(path, encoding="utf-8") as fh:
            for n, line in enumerate(fh, 1):
                for label, rx in BLOCK:
                    m = rx.search(line)
                    if m and not any(h in line for h in SAFE_HINTS):
                        errors.append(f"{path}:{n}  [{label}]  {m.group()[:60]}")
                for label, rx in WARN:
                    m = rx.search(line)
                    if m and not any(h in line for h in SAFE_HINTS):
                        warnings.append(f"{path}:{n}  [{label}]  {m.group()[:60]}")
    except (UnicodeDecodeError, IsADirectoryError):
        continue

for w in warnings:
    print("⚠️  (확인 필요)", w)

if errors:
    print("\n❌ 외부망에 두면 안 되는 정보가 발견됐습니다 (반드시 제거):")
    for e in errors:
        print("   -", e)
    sys.exit(1)

print("✅ 실제 주소·비밀번호·개인정보 없음")
PY
