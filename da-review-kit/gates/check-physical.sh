#!/usr/bin/env bash
# =====================================================================
# check-physical.sh · DA 물리 검토 게이트
#  표준/비표준 판정: ① 입력 table.standard  ② schema∈standard_schemas  ③ default_standard
#     → 비표준 테이블은 검토 제외(건너뜀)
#  [테이블명] 구조 + 앱/소그룹 코드 등록
#  [컬럼명]  컬럼 = [수식어]+[도메인 끝말]:
#     ① 도메인(인포타입)으로 끝나는가  ② 수식어가 표준단어/도메인단어인가
#     ③ 한글↔영문 표준 일치  ④ 인포타입 도메인·길이 일관(복수허용)
#     + 끝자리숫자(스위치), 한글 길이, 표준화적용여부(컬럼) 게이팅
#  [기타] PK, 감사컬럼(경고), M:N 금지
# 사용: ./check-physical.sh <review-target.yaml> [standard-meta.yaml]
# =====================================================================
set -euo pipefail
INPUT="${1:-input/review-target.good.yaml}"
META="${2:-$(dirname "$0")/../meta/standard-meta.yaml}"

python3 - "$INPUT" "$META" <<'PY'
import sys, re
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

inp = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))
meta = yaml.safe_load(open(sys.argv[2], encoding="utf-8"))
nm = meta["naming"]; cr = meta["column"]
tpat = nm["table"]["pattern"]
sys_codes = set(nm["table"]["system_codes"]); apps = set(nm["valid_app_codes"]); subs = set(nm["valid_subgroup_codes"])
words = meta.get("standard_words", {}) or {}
import os as _os
_swf = _os.path.join(_os.path.dirname(sys.argv[2]), "standard-words.yaml")
if _os.path.exists(_swf):
    _sw = yaml.safe_load(open(_swf, encoding="utf-8")) or {}
    words = {**(_sw.get("standard_words", {}) or {}), **words}   # 별도 단어사전 병합(인라인 우선)
domains = meta.get("domains", {}) or {}
end_exc = meta.get("end_word_exceptions", {}) or {}
audit_req = set(meta.get("audit_columns", {}).get("recommended", []))
maxk = cr.get("korean_max_chars_server", 999)
estyle = cr.get("english_style", "upper_snake")   # 영문변수명 규칙: camelCase / upper_snake
# 수식어 후보 = 표준단어 + 도메인단어 (예: '수수료금액'의 '수수료'도 인정) — 한글→영문약어 맵
mod_tokens = {**words, **{k: v["abbr"] for k, v in domains.items()}}

def to_eng(abbrs):
    # 표준약어 리스트 → 영문변수명. camelCase면 첫단어 소문자+이후 첫글자 대문자(고객성별→custSex),
    # upper_snake면 대문자_결합(고객성별→CUST_SEX). 약어 내부 '_'(예 DV_CD)는 분해해서 적용.
    parts = []
    for a in abbrs: parts += str(a).split("_")
    if estyle == "camelCase":
        return "".join(p.lower() if i == 0 else p[:1].upper()+p[1:].lower() for i, p in enumerate(parts))
    return "_".join(parts)
# 표준/비표준 판정 설정
std_schemas = set(meta.get("standard_schemas", []) or [])
default_std = meta.get("default_standard", True)

def tokenize_mod(kr):
    keys = sorted(mod_tokens, key=len, reverse=True); toks, i = [], 0
    while i < len(kr):
        for k in keys:
            if kr.startswith(k, i): toks.append(k); i += len(k); break
        else: return None
    return toks
def find_endword(kr):
    cands = [w for w in list(domains)+list(end_exc) if kr.endswith(w)]
    return max(cands, key=len) if cands else None
def split_infotype(s):
    cands = [d for d in domains if s.startswith(d)]
    if not cands: return None, None
    d = max(cands, key=len); return d, s[len(d):]
def is_standard(t):
    s = t.get("standard")
    if s is not None: return bool(s)
    sch = t.get("schema") or inp.get("schema")
    return (sch in std_schemas) if std_schemas else default_std

errors, warns, skipped = [], [], []
for t in inp.get("tables", []):
    tn = t.get("physical_name", ""); tag = f"[{tn or '?'}]"
    if not is_standard(t):                 # 비표준 테이블 → 검토 제외
        skipped.append(tn or "?"); continue
    # ===== 테이블 명명규칙 =====
    if not re.match(tpat, tn):
        errors.append(f"{tag} 테이블명이 명명규칙에 안 맞음 (규칙 {tpat})")
    else:
        sysc, app, sg = tn[1], tn[2:5], tn[5:7]
        if sysc not in sys_codes: errors.append(f"{tag} 시스템구분 '{sysc}' 표준 {sorted(sys_codes)} 아님")
        if app not in apps:       errors.append(f"{tag} 어플리케이션코드 '{app}' 미등록")
        if sg not in subs:        errors.append(f"{tag} 업무소그룹코드 '{sg}' 미등록")

    cols = t.get("columns", []) or []
    for c in cols:
        if c.get("std", True) is False:    # 표준화적용여부=N 컬럼 → 검사 건너뜀
            continue
        kr = str(c.get("korean", "")).strip(); en = str(c.get("english", "")).strip()
        it = str(c.get("infotype", "")).strip()
        if cr.get("require_korean") and not kr: errors.append(f"{tag} 컬럼 한글명 누락(영문 '{en}')"); continue
        if cr.get("require_english") and not en: errors.append(f"{tag} 컬럼 '{kr}' 영문명 누락")
        if cr.get("require_infotype") and not it: errors.append(f"{tag} 컬럼 '{kr}' 인포타입 미기재")
        forbid_td = cr.get("forbid_trailing_digit")
        if forbid_td:
            if kr[-1:].isdigit(): errors.append(f"{tag} 컬럼 '{kr}' 한글명 끝자리 숫자 금지")
            if en[-1:].isdigit(): errors.append(f"{tag} 컬럼 '{kr}' 영문명 '{en}' 끝자리 숫자 금지")
        kr_m = kr if forbid_td else re.sub(r"\d+$", "", kr)
        en_m = en if forbid_td else re.sub(r"\d+$", "", en)
        if len(kr) > maxk: errors.append(f"{tag} 컬럼 '{kr}' 한글명 {len(kr)}자 > 최대 {maxk}자")
        # 도메인 결정: 인포타입이 있으면 그것을 진실의 근원으로(중첩 도메인 명50/고객명6 공존 지원),
        #              없으면 종전처럼 longest-match 끝말 추측(하위호환)
        if it:
            idom, ilen = split_infotype(it)
            if idom is None:
                errors.append(f"{tag} 컬럼 '{kr}' 인포타입 '{it}' 의 도메인이 표준 도메인 아님"); continue
            if kr_m.endswith(idom):
                ew = idom
            else:
                ew = next((x for x, mp in end_exc.items() if mp == idom and kr_m.endswith(x)), None)
            if ew is None:
                errors.append(f"{tag} 컬럼 '{kr}' 가 인포타입 도메인 '{idom}' 으로 끝나지 않음"); continue
            dom = idom; d = domains[dom]; prefix = kr_m[:-len(ew)]
            if d["lengths"] and ilen not in d["lengths"]:
                errors.append(f"{tag} 컬럼 '{kr}' 인포타입 길이 '{ilen}' 비허용 (허용 {d['lengths']})")
        else:
            ew = find_endword(kr_m)
            if not ew:
                errors.append(f"{tag} 컬럼 '{kr}' 가 도메인(인포타입)으로 끝나지 않음"); continue
            dom = end_exc.get(ew, ew); d = domains[dom]; prefix = kr_m[:-len(ew)]
        mod = tokenize_mod(prefix) if prefix else []
        if prefix and mod is None:
            errors.append(f"{tag} 컬럼 '{kr}' 수식어 '{prefix}' 에 비표준단어 포함")
        if en and mod is not None:
            expected = to_eng([mod_tokens[w] for w in mod] + [d["abbr"]])
            if en_m != expected:
                errors.append(f"{tag} 컬럼 영문명 '{en}' 불일치 (한글 '{kr}' 기준 기대 '{expected}')")

    if meta.get("pk", {}).get("require") and not any(c.get("pk") for c in cols):
        errors.append(f"{tag} PK(식별자) 미설정")
    miss = audit_req - {c.get("english") for c in cols}
    if miss: warns.append(f"{tag} 권장 감사컬럼 누락: {sorted(miss)}")
    for r in (t.get("relationships") or []):
        if str(r.get("type","")).upper().replace(" ","") in ("M:N","M:M","N:M"):
            errors.append(f"{tag} M:N 직접관계({r.get('to')}) — 연결엔티티로 분해 필요")

import os, json, datetime
def _suggest(msg):                               # 결정적 권고(고치는 법)
    m = re.search(r"기대 '([^']+)'", msg)
    if "영문명" in msg and "불일치" in msg and m: return f"영문명을 '{m.group(1)}' 로 변경(camelCase)"
    if "테이블명이 명명규칙" in msg:       return "T+시스템(H/S)+앱(3)+소그룹(2)+일련(2)=9자 형식으로 수정"
    if "시스템구분" in msg:                return "시스템구분을 H(호스트)/S(서버) 중 하나로"
    if "어플리케이션코드" in msg:          return "표준 등록 앱코드로 변경(미등록이면 표준 등록 요청)"
    if "업무소그룹코드" in msg:            return "표준 등록 소그룹코드로 변경(미등록이면 표준 등록 요청)"
    if "도메인(인포타입)으로 끝나지 않음" in msg: return "표준 도메인 끝말로 끝나게 컬럼명 수정(예: ~번호/~금액/~일시)"
    if "인포타입 도메인" in msg and "불일치" in msg: return "인포타입 도메인을 컬럼 끝말 도메인과 일치시키기"
    if "인포타입 길이" in msg and "비허용" in msg:
        mm = re.search(r"허용 (\[.*\])", msg);  return f"허용 길이 {mm.group(1) if mm else ''} 중 하나로 변경"
    if "수식어" in msg and "비표준" in msg: return "수식어를 표준단어로 교체(또는 표준단어로 등록)"
    if "한글명" in msg and "최대" in msg:  return "한글명을 최대 길이 이내로 축약"
    if "한글명 누락" in msg:               return "컬럼 한글명 기입"
    if "영문명 누락" in msg:               return "영문명(camelCase) 기입"
    if "인포타입 미기재" in msg:           return "인포타입(도메인+길이) 기입"
    if "끝자리 숫자" in msg:               return "끝자리 숫자 제거"
    if "PK(식별자) 미설정" in msg:         return "기본키(PK) 컬럼 지정"
    if "M:N 직접관계" in msg:              return "연결(교차) 엔티티로 분해"
    if "감사컬럼 누락" in msg:             return "권장 감사컬럼(sysLstPrcDtm, sysLstUsrNo) 추가"
    return ""
def _finding(sev, msg):
    scope = msg[1:msg.index("]")] if msg.startswith("[") and "]" in msg else None
    cat = "missing" if any(k in msg for k in ("누락", "미기재", "미설정")) else "violation"
    return {"severity": sev, "category": cat, "scope": scope, "message": msg, "suggestion": _suggest(msg)}
result = {
    "harness": "da-review", "gate": "check-physical", "target": sys.argv[1],
    "project": inp.get("project"), "status": "failed" if errors else "passed",
    "summary": {"errors": len(errors), "warnings": len(warns)},
    "skipped_nonstandard": skipped,
    "findings": [_finding("error", e) for e in errors] + [_finding("warning", w) for w in warns],
    "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
}
if os.environ.get("DA_OUT"):
    json.dump(result, open(os.environ["DA_OUT"], "w", encoding="utf-8"), ensure_ascii=False, indent=2)

print(f"검토대상: {inp.get('project','?')}  /  테이블 {len(inp.get('tables',[]))}개")
if skipped: print(f"⏭️  비표준 테이블 검토 제외: {skipped}")
print()
if warns:
    print("⚠️  경고:"); [print("   -", w) for w in warns]; print()
if errors:
    print(f"❌ DA 물리검토 반송 — 위반 {len(errors)}건:")
    for e in errors: print("   -", e)
    sys.exit(1)
print("✅ DA 물리검토 통과 — 이름조합·명명규칙·인포타입 표준 충족")
PY
