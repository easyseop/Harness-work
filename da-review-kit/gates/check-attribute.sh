#!/usr/bin/env bash
# =====================================================================
# check-attribute.sh · DA 속성명 별도검증 게이트
#  컬럼명 검증(check-physical)과 짝. 메타의 '속성명'을 따로 본다.
#   A. 속성명도 표준 조합인가  : [수식어 표준단어] + [도메인 끝말]
#   B. 컬럼명 ↔ 속성명 정합성   : 같은 도메인을 쓰는가, 컬럼 수식어가 속성에 포함되는가
#  (속성명 미기재 시 컬럼한글명을 속성명으로 간주. 표준화적용여부=N 컬럼은 건너뜀)
# 사용: ./check-attribute.sh <review-target.yaml> [standard-meta.yaml]
# =====================================================================
set -euo pipefail
INPUT="${1:-input/review-target.good.yaml}"
META="${2:-$(dirname "$0")/../meta/standard-meta.yaml}"

python3 - "$INPUT" "$META" <<'PY'
import sys
try:
    import yaml
except ImportError:
    print("⚠️  pyyaml 이 없습니다. 설치: pip install pyyaml"); sys.exit(2)

inp = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))
meta = yaml.safe_load(open(sys.argv[2], encoding="utf-8"))
words = meta.get("standard_words", {}) or {}
domains = meta.get("domains", {}) or {}
end_exc = meta.get("end_word_exceptions", {}) or {}
mod_tokens = {**words, **{k: v["abbr"] for k, v in domains.items()}}   # 수식어 = 표준단어 + 도메인단어
std_schemas = set(meta.get("standard_schemas", []) or [])
default_std = meta.get("default_standard", True)

def tokenize_mod(kr):
    keys = sorted(mod_tokens, key=len, reverse=True); toks, i = [], 0
    while i < len(kr):
        for k in keys:
            if kr.startswith(k, i): toks.append(k); i += len(k); break
        else: return None
    return toks
def endword(kr):
    cands = [w for w in list(domains)+list(end_exc) if kr.endswith(w)]
    return max(cands, key=len) if cands else None
def domain_of(ew): return end_exc.get(ew, ew)
def is_standard(t):
    s = t.get("standard")
    if s is not None: return bool(s)
    sch = t.get("schema") or inp.get("schema")
    return (sch in std_schemas) if std_schemas else default_std

errors, skipped = [], []
for t in inp.get("tables", []):
    tag = f"[{t.get('physical_name','?')}]"
    if not is_standard(t):
        skipped.append(t.get("physical_name", "?")); continue
    for c in (t.get("columns") or []):
        if c.get("std", True) is False: continue
        kr = str(c.get("korean", "")).strip()
        attr = str(c.get("attribute", "") or kr).strip()
        if not attr: continue
        # A. 속성명 표준 조합
        ew_a = endword(attr)
        if not ew_a:
            errors.append(f"{tag} 속성명 '{attr}' 가 도메인으로 끝나지 않음"); continue
        dom_a = domain_of(ew_a); pre_a = attr[:-len(ew_a)]
        mod_a = tokenize_mod(pre_a) if pre_a else []
        if pre_a and mod_a is None:
            errors.append(f"{tag} 속성명 '{attr}' 수식어 '{pre_a}' 에 비표준단어 포함")
        # B. 컬럼명 ↔ 속성명 정합성
        ew_c = endword(kr)
        if ew_c:
            dom_c = domain_of(ew_c)
            if dom_c != dom_a:
                errors.append(f"{tag} 컬럼 '{kr}' 도메인('{dom_c}')이 속성 '{attr}' 도메인('{dom_a}')과 불일치")
            mod_c = tokenize_mod(kr[:-len(ew_c)]) if kr[:-len(ew_c)] else []
            if mod_c is not None and mod_a is not None:
                extra = [w for w in mod_c if w not in mod_a]
                if extra:
                    errors.append(f"{tag} 컬럼 '{kr}' 수식어 {extra} 가 속성 '{attr}' 에 없음")

import os, json, datetime
def _suggest(msg):                               # 결정적 권고(고치는 법)
    if "도메인으로 끝나지 않음" in msg:      return "표준 도메인 끝말로 끝나게 속성명 수정"
    if "수식어" in msg and "비표준" in msg:  return "수식어를 표준단어로 교체(또는 표준단어로 등록)"
    if "도메인" in msg and "불일치" in msg:  return "컬럼과 속성의 도메인을 일치시키기(동종 속성 동일 도메인)"
    if "속성" in msg and "에 없음" in msg:   return "속성명에 해당 수식어 반영(또는 컬럼 수식어 제거)"
    return ""
def _finding(sev, msg):                          # 반송사유 틀: 대상(scope)+권고(suggestion)
    scope = msg[1:msg.index("]")] if msg.startswith("[") and "]" in msg else None
    cat = "missing" if any(k in msg for k in ("누락", "미기재", "미설정")) else "violation"
    return {"severity": sev, "category": cat, "scope": scope, "message": msg, "suggestion": _suggest(msg)}
result = {
    "harness": "da-review", "gate": "check-attribute", "target": sys.argv[1],
    "project": inp.get("project"), "status": "failed" if errors else "passed",
    "summary": {"errors": len(errors), "warnings": 0},
    "skipped_nonstandard": skipped,
    "findings": [_finding("error", e) for e in errors],
    "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
}
if os.environ.get("DA_OUT"):
    json.dump(result, open(os.environ["DA_OUT"], "w", encoding="utf-8"), ensure_ascii=False, indent=2)

print(f"검토대상: {inp.get('project','?')}")
if skipped: print(f"⏭️  비표준 테이블 검토 제외: {skipped}")
print()
if errors:
    print(f"❌ 속성명 검증 반송 — 위반 {len(errors)}건:")
    for e in errors: print("   -", e)
    sys.exit(1)
print("✅ 속성명 검증 통과 — 속성명 표준 + 컬럼명↔속성명 정합")
PY
