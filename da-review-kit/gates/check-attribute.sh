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

def tokenize_mod(kr):
    keys = sorted(words, key=len, reverse=True); toks, i = [], 0
    while i < len(kr):
        for k in keys:
            if kr.startswith(k, i): toks.append(k); i += len(k); break
        else: return None
    return toks
def endword(kr):
    cands = [w for w in list(domains)+list(end_exc) if kr.endswith(w)]
    return max(cands, key=len) if cands else None
def domain_of(ew): return end_exc.get(ew, ew)

errors = []
for t in inp.get("tables", []):
    tag = f"[{t.get('physical_name','?')}]"
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
result = {
    "harness": "da-review", "gate": "check-attribute", "target": sys.argv[1],
    "project": inp.get("project"), "status": "failed" if errors else "passed",
    "summary": {"errors": len(errors), "warnings": 0},
    "findings": [{"severity": "error", "message": e} for e in errors],
    "generated_at": datetime.datetime.now().isoformat(timespec="seconds"),
}
if os.environ.get("DA_OUT"):
    json.dump(result, open(os.environ["DA_OUT"], "w", encoding="utf-8"), ensure_ascii=False, indent=2)

print(f"검토대상: {inp.get('project','?')}\n")
if errors:
    print(f"❌ 속성명 검증 반송 — 위반 {len(errors)}건:")
    for e in errors: print("   -", e)
    sys.exit(1)
print("✅ 속성명 검증 통과 — 속성명 표준 + 컬럼명↔속성명 정합")
PY
