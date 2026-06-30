#!/usr/bin/env bash
# =====================================================================
# intake/check-ready.sh · DA검토 사전점검 (앞단)
#   게이트(검사) 실행 전에:
#     ① 표준여부 확인  — table.standard / schema∈standard_schemas / 미명시(확인 권고)
#     ② 정보 충분성 점검 — 표준 테이블이 표준검사에 필요한 필수정보를 갖췄나
#   결론: "보완 필요" 또는 "준비 완료 → 게이트 실행 가능"
#   ※ LLM 변환(비정형 설계도 → 이 INPUT) 은 이 단계 '앞'의 별도 어댑터(hook). README 참고.
# 사용: ./check-ready.sh <candidate-input.yaml> [standard-meta.yaml]
# 통과(준비완료): exit 0  /  보완필요: exit 1
# =====================================================================
set -euo pipefail
INPUT="${1:?사용법: check-ready.sh <candidate.yaml> [meta]}"
META="${2:-$(dirname "$0")/../meta/standard-meta.yaml}"

python3 - "$INPUT" "$META" <<'PY'
import sys, yaml
inp = yaml.safe_load(open(sys.argv[1], encoding="utf-8")) or {}
meta = yaml.safe_load(open(sys.argv[2], encoding="utf-8"))
std_schemas = set(meta.get("standard_schemas", []) or [])
default_std = meta.get("default_standard", True)
REQUIRED_COL = ["korean", "english", "infotype"]   # 표준검사에 필요한 최소 컬럼 정보

def std_state(t):
    if t.get("standard") is not None:
        return ("표준" if t["standard"] else "비표준"), "명시"
    sch = t.get("schema") or inp.get("schema")
    if std_schemas:
        return ("표준" if sch in std_schemas else "비표준"), "스키마판정"
    return ("표준" if default_std else "비표준"), "기본값(미명시)"

ask, shortage = [], []     # 표준여부 확인권고 / 정보부족
print("== DA검토 사전점검 (intake) ==\n")
print("[표준여부]")
for t in inp.get("tables", []) or []:
    nm = t.get("physical_name", "?"); state, src = std_state(t)
    mark = {"표준":"✅ 검토대상","비표준":"⏭️ 검토제외"}[state]
    note = "  ❓ 표준여부 미명시 → 확인 권고" if src.startswith("기본값") else f"  ({src})"
    print(f"  - {nm:14s} {state}  {mark}{note}")
    if src.startswith("기본값"): ask.append(nm)
    if state != "표준": continue
    # 표준 테이블만 정보 충분성 점검
    cols = t.get("columns") or []
    if not cols: shortage.append(f"{nm}: 컬럼 정보 없음"); continue
    for c in cols:
        miss = [k for k in REQUIRED_COL if not str(c.get(k, "")).strip()]
        if miss: shortage.append(f"{nm}.{c.get('korean') or c.get('english') or '?'}: {miss} 누락")
    if not any(c.get("pk") for c in cols): shortage.append(f"{nm}: PK 표시된 컬럼 없음")

if shortage:
    print("\n[정보 부족 — 보완 필요]")
    for s in shortage: print("   -", s)
if ask:
    print(f"\n[표준여부 확인 권고] {ask}  (standard: true/false 적거나 schema 등록 권장)")

print("\n== 결론 ==")
if shortage:
    print("❌ 부족한 정보가 있습니다. 다음 중 선택하세요:")
    print("  [1] 부족 정보를 채워서 다시 검토   (권장)")
    print("  [2] 부족한 채로 게이트 실행        (부족분도 반송사유 category=missing 으로 표시)")
    print("  [3] 해당 테이블/컬럼을 비표준으로 제외하고 진행")
    print("  [4] 중단")
    sys.exit(1)
print("✅ 준비 완료 — gates/check-physical.sh 등 실행 가능"
      + ("  (표준여부 미명시 항목은 기본값으로 진행)" if ask else ""))
PY
