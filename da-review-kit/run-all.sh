#!/usr/bin/env bash
# =====================================================================
# run-all.sh · input/ 의 모든 산출물을 한 번에 검사
#   - 파일 형식 자동 판별: tables: → DB설계서 / instance_names: → 인스턴스코드 정의서
#   - DB설계서 = check-physical + check-attribute,  인스턴스코드 = check-instance-code
#   - 각 줄에 통과(✅)/반송(❌) 요약 출력
# 사용: bash run-all.sh            (입력 폴더 기본 input/)
#       bash run-all.sh <폴더>     (다른 폴더 지정)
# =====================================================================
set -u
cd "$(dirname "$0")"
DIR="${1:-input}"
OUTDIR="${2:-results}"           # 결과 JSON 저장 폴더 (기본 results/)
mkdir -p "$OUTDIR"
pass=0; fail=0

printf "%-32s %-20s %s\n" "입력 산출물" "게이트" "결과"
echo "----------------------------------------------------------------------"
for f in "$DIR"/*.yaml "$DIR"/*.json; do
  [ -e "$f" ] || continue
  kind=$(python3 -c "import yaml,sys
try: d=yaml.safe_load(open('$f',encoding='utf-8')) or {}
except Exception: d={}
print('db' if 'tables' in d else ('inst' if 'instance_names' in d else '?'))" 2>/dev/null)
  case "$kind" in
    db)   gates="check-physical check-attribute" ;;
    inst) gates="check-instance-code" ;;
    *)    printf "%-32s %-20s %s\n" "$(basename "$f")" "-" "⏭️  알수없는형식(건너뜀)"; continue ;;
  esac
  for g in $gates; do
    base="$(basename "${f%.*}")"
    out="$OUTDIR/${base}.${g}.json"            # 예: results/review-target.bad.check-physical.json
    if DA_OUT="$out" bash "gates/$g.sh" "$f" >/dev/null 2>&1; then
      printf "%-32s %-20s %s\n" "$(basename "$f")" "$g" "✅ 통과"; pass=$((pass+1))
    else
      printf "%-32s %-20s %s\n" "$(basename "$f")" "$g" "❌ 반송"; fail=$((fail+1))
    fi
  done
done
echo "----------------------------------------------------------------------"
echo "합계: 통과 $pass · 반송 $fail"
echo "상세 결과(JSON): $OUTDIR/  (입력파일.게이트.json 으로 각각 저장됨)"

