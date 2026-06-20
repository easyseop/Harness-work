#!/usr/bin/env bash
# =====================================================================
# check-instance-code.sh · 인스턴스코드 정의서 검증 게이트
#  [명명규칙] 업무인스턴스명:
#     ① 끝말(~구분코드/~코드/~여부/~유무)  ② 수식어 표준단어  ③ 단독사용금지 12단어
#     ④ 공백/특수문자 금지  ⑤ 인스턴스명 중복 금지
#  [코드값규칙] 업무인스턴스코드:
#     ⑥ 시트2 인스턴스명은 시트1에 존재(정합)  ⑦ ~여부/~유무 = 0/1만
#     ⑧ 코드 길이 = code_length  ⑨ [0]=해당무 / [9]=기타 (경고)
# 사용: ./check-instance-code.sh <instance-code.yaml> [standard-meta.yaml]
# =====================================================================
set -euo pipefail
INPUT="${1:-input/instance-code.good.yaml}"
META="${2:-$(dirname "$0")/../meta/standard-meta.yaml}"

python3 - "$INPUT" "$META" <<'PY'
import sys, re
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

inp = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))
meta = yaml.safe_load(open(sys.argv[2], encoding="utf-8"))
words = meta.get("standard_words", {}) or {}
ic = meta.get("instance_code", {}) or {}
endings = sorted(ic.get("name_endings", []), key=len, reverse=True)
yn_endings = ic.get("yn_endings", [])
forbidden = set(ic.get("forbidden_standalone", []))
zero_ok = set(ic.get("zero_meanings", [])); nine_ok = set(ic.get("nine_meanings", []))

def tokenize(kr):
    keys = sorted(words, key=len, reverse=True); toks, i = [], 0
    while i < len(kr):
        for k in keys:
            if kr.startswith(k, i): toks.append(k); i += len(k); break
        else: return None
    return toks
def ending_of(nm):
    for e in endings:
        if nm.endswith(e): return e
    return None

errors, warns = [], []
names = inp.get("instance_names", []) or []
values = inp.get("code_values", []) or []

# ===== 시트1: 업무인스턴스명 명명규칙 =====
seen = set(); name_len = {}; name_end = {}
for it in names:
    nm = str(it.get("instance_name", "")).strip()
    tag = f"[{nm or '?'}]"
    if not nm: errors.append("인스턴스명 누락"); continue
    name_len[nm] = it.get("code_length");
    if not re.match(r"^[가-힣A-Za-z0-9]+$", nm):
        errors.append(f"{tag} 공백/특수문자 사용 불가")
    if nm in forbidden:
        errors.append(f"{tag} 단독사용금지 단어 (단독으로 인스턴스명 불가)")
    if nm in seen: errors.append(f"{tag} 인스턴스명 중복")
    seen.add(nm)
    ew = ending_of(nm); name_end[nm] = ew
    if not ew:
        errors.append(f"{tag} 끝말 규칙 위반 (~구분코드/~코드/~여부/~유무 로 끝나야)")
    else:
        mod = nm[:-len(ew)]
        if mod and tokenize(mod) is None:
            errors.append(f"{tag} 수식어 '{mod}' 에 비표준단어 포함")

# ===== 시트2: 코드값 규칙 =====
from collections import defaultdict
grp = defaultdict(list)
for cv in values:
    grp[str(cv.get("instance_name","")).strip()].append(cv)

for nm, items in grp.items():
    tag = f"[{nm}]"
    if nm not in seen:
        errors.append(f"{tag} 시트2 인스턴스명이 시트1(업무인스턴스명정의서)에 없음"); continue
    clen = name_len.get(nm); ew = name_end.get(nm)
    codes = {str(cv.get("code","")).strip() for cv in items}
    # ⑦ 여부/유무 = 0/1만
    if ew in yn_endings and not codes <= {"0", "1"}:
        errors.append(f"{tag} ~{ew} 는 코드값 0/1 만 허용 (현재 {sorted(codes)})")
    is_yn = ew in yn_endings
    for cv in items:
        code = str(cv.get("code","")).strip(); content = str(cv.get("content","")).strip()
        if clen and len(code) != int(clen):
            errors.append(f"{tag} 코드 '{code}' 길이가 code_length({clen})와 다름")
        if not is_yn:   # ~여부/~유무는 0=부/무 라 예약의미 검사 제외
            if set(code) == {"0"} and content not in zero_ok:
                warns.append(f"{tag} 코드 '{code}' 의미는 보통 해당무 (현재 '{content}')")
            if set(code) == {"9"} and content not in nine_ok:
                warns.append(f"{tag} 코드 '{code}' 의미는 보통 기타 (현재 '{content}')")

print(f"검토대상: {inp.get('project','?')}  /  인스턴스 {len(names)}개·코드값 {len(values)}건\n")
if warns:
    print("⚠️  경고:"); [print("   -", w) for w in warns]; print()
if errors:
    print(f"❌ 인스턴스코드 정의서 반송 — 위반 {len(errors)}건:")
    for e in errors: print("   -", e)
    sys.exit(1)
print("✅ 인스턴스코드 정의서 통과 — 명명규칙·코드값규칙 충족")
PY
