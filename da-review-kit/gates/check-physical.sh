#!/usr/bin/env bash
# =====================================================================
# check-physical.sh · DA 물리 검토 게이트
#  우선순위: ① 이름 조합(수식어+도메인 끝말)  ② 테이블/컬럼 명명규칙
#  [테이블명] 구조 + 앱/소그룹 코드 등록
#  [컬럼명]  컬럼 = [수식어]+[도메인 끝말]:
#     ① 도메인(인포타입)으로 끝나는가          ② 수식어가 표준단어인가
#     ③ 한글 ↔ 영문 표준 일치                  ④ 인포타입 도메인·길이 일관(복수허용)
#     + 끝자리숫자 금지, 한글 길이, 표준화적용여부(컬럼) 게이팅
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
domains = meta.get("domains", {}) or {}
end_exc = meta.get("end_word_exceptions", {}) or {}
audit_req = set(meta.get("audit_columns", {}).get("recommended", []))
maxk = cr.get("korean_max_chars_server", 999)

def tokenize_mod(kr):
    keys = sorted(words, key=len, reverse=True); toks, i = [], 0
    while i < len(kr):
        for k in keys:
            if kr.startswith(k, i): toks.append(k); i += len(k); break
        else: return None
    return toks
def find_endword(kr):
    cands = [w for w in list(domains)+list(end_exc) if kr.endswith(w)]
    return max(cands, key=len) if cands else None
def split_infotype(s):                       # 인포타입 → (도메인, 길이)
    cands = [d for d in domains if s.startswith(d)]
    if not cands: return None, None
    d = max(cands, key=len); return d, s[len(d):]

errors, warns = [], []
for t in inp.get("tables", []):
    tn = t.get("physical_name", ""); tag = f"[{tn or '?'}]"
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
        if c.get("std", True) is False:      # 표준화적용여부=N → 검사 건너뜀
            continue
        kr = str(c.get("korean", "")).strip(); en = str(c.get("english", "")).strip()
        it = str(c.get("infotype", "")).strip()
        if cr.get("require_korean") and not kr: errors.append(f"{tag} 컬럼 한글명 누락(영문 '{en}')"); continue
        if cr.get("require_english") and not en: errors.append(f"{tag} 컬럼 '{kr}' 영문명 누락")
        if cr.get("require_infotype") and not it: errors.append(f"{tag} 컬럼 '{kr}' 인포타입 미기재")
        if cr.get("forbid_trailing_digit"):
            if kr[-1:].isdigit(): errors.append(f"{tag} 컬럼 '{kr}' 한글명 끝자리 숫자 금지")
            if en[-1:].isdigit(): errors.append(f"{tag} 컬럼 '{kr}' 영문명 '{en}' 끝자리 숫자 금지")
        if len(kr) > maxk: errors.append(f"{tag} 컬럼 '{kr}' 한글명 {len(kr)}자 > 최대 {maxk}자")
        # ① 도메인 끝말
        ew = find_endword(kr)
        if not ew:
            errors.append(f"{tag} 컬럼 '{kr}' 가 도메인(인포타입)으로 끝나지 않음"); continue
        dom = end_exc.get(ew, ew); d = domains[dom]; prefix = kr[:-len(ew)]
        # ② 수식어 표준단어
        mod = tokenize_mod(prefix) if prefix else []
        if prefix and mod is None:
            errors.append(f"{tag} 컬럼 '{kr}' 수식어 '{prefix}' 에 비표준단어 포함")
        # ③ 한글 ↔ 영문 일치
        if en and mod is not None:
            expected = "_".join([words[w] for w in mod] + [d["abbr"]])
            if en != expected:
                errors.append(f"{tag} 컬럼 영문명 '{en}' 불일치 (한글 '{kr}' 기준 기대 '{expected}')")
        # ④ 인포타입 도메인·길이 일관
        if it:
            idom, ilen = split_infotype(it)
            if idom != dom:
                errors.append(f"{tag} 컬럼 '{kr}' 인포타입 도메인 '{idom}' 이 끝말 '{dom}' 과 불일치")
            elif d["lengths"] and ilen not in d["lengths"]:
                errors.append(f"{tag} 컬럼 '{kr}' 인포타입 길이 '{ilen}' 비허용 (허용 {d['lengths']})")

    if meta.get("pk", {}).get("require") and not any(c.get("pk") for c in cols):
        errors.append(f"{tag} PK(식별자) 미설정")
    miss = audit_req - {c.get("english") for c in cols}
    if miss: warns.append(f"{tag} 권장 감사컬럼 누락: {sorted(miss)}")
    for r in (t.get("relationships") or []):
        if str(r.get("type","")).upper().replace(" ","") in ("M:N","M:M","N:M"):
            errors.append(f"{tag} M:N 직접관계({r.get('to')}) — 연결엔티티로 분해 필요")

print(f"검토대상: {inp.get('project','?')}  /  테이블 {len(inp.get('tables',[]))}개\n")
if warns:
    print("⚠️  경고:"); [print("   -", w) for w in warns]; print()
if errors:
    print(f"❌ DA 물리검토 반송 — 위반 {len(errors)}건:")
    for e in errors: print("   -", e)
    sys.exit(1)
print("✅ DA 물리검토 통과 — 이름조합·명명규칙·인포타입 표준 충족")
PY
