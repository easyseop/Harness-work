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
domains = meta.get("domains", {}) or {}
mod_tokens = {**words, **{k: v["abbr"] for k, v in domains.items()}}   # 수식어 = 표준단어 + 도메인단어
ic = meta.get("instance_code", {}) or {}
endings = sorted(ic.get("name_endings", []), key=len, reverse=True)
yn_endings = ic.get("yn_endings", [])
forbidden = set(ic.get("forbidden_standalone", []))
zero_ok = set(ic.get("zero_meanings", [])); nine_ok = set(ic.get("nine_meanings", []))

def tokenize(kr):
    keys = sorted(mod_tokens, key=len, reverse=True); toks, i = [], 0
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

import os, json, datetime
def _suggest(msg):                               # 결정적 권고(고치는 법)
    if "인스턴스명 누락" in msg:           return "업무인스턴스명 기입"
    if "공백/특수문자" in msg:             return "공백·특수문자 제거(한글/영문/숫자만)"
    if "단독사용금지" in msg:              return "수식어를 붙여 구체화 (예: 신용여부)"
    if "인스턴스명 중복" in msg:           return "중복 인스턴스명 제거/통합"
    if "끝말 규칙 위반" in msg:            return "~구분코드/~코드/~여부/~유무 로 끝나게 변경"
    if "수식어" in msg and "비표준" in msg: return "수식어를 표준단어로 교체(또는 표준단어로 등록)"
    if "시트1" in msg and "없음" in msg:   return "시트1(업무인스턴스명정의서)에 추가하거나 시트2에서 제거"
    if "코드값 0/1 만 허용" in msg:        return "코드값을 0/1 로 정리(또는 ~구분코드로 변경)"
    if "길이가 code_length" in msg:        return "코드 길이를 code_length 에 맞추기"
    if "해당무" in msg:                    return "코드 0 은 '해당무' 의미로 사용 권장"
    if "기타" in msg:                      return "코드 9 는 '기타' 의미로 사용 권장"
    return ""
def _finding(sev, msg):                          # 반송사유 틀: 대상(scope)+권고(suggestion)
    scope = msg[1:msg.index("]")] if msg.startswith("[") and "]" in msg else None
    cat = "missing" if any(k in msg for k in ("누락", "미기재", "미설정")) else "violation"
    return {"severity": sev, "category": cat, "scope": scope, "message": msg, "suggestion": _suggest(msg)}
result = {
    "harness": "da-review", "gate": "check-instance-code", "target": sys.argv[1],
    "project": inp.get("project"), "status": "failed" if errors else "passed",
    "summary": {"errors": len(errors), "warnings": len(warns)},
    "findings": [_finding("error", e) for e in errors] + [_finding("warning", w) for w in warns],
    "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
}
if os.environ.get("DA_OUT"):
    json.dump(result, open(os.environ["DA_OUT"], "w", encoding="utf-8"), ensure_ascii=False, indent=2)

print(f"검토대상: {inp.get('project','?')}  /  인스턴스 {len(names)}개·코드값 {len(values)}건\n")
if warns:
    print("⚠️  경고:"); [print("   -", w) for w in warns]; print()
if errors:
    print(f"❌ 인스턴스코드 정의서 반송 — 위반 {len(errors)}건:")
    for e in errors: print("   -", e)
    sys.exit(1)
print("✅ 인스턴스코드 정의서 통과 — 명명규칙·코드값규칙 충족")
PY
