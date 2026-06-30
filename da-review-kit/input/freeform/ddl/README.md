# 자유양식 DDL 데이터셋 — 변환→검사 시연용

자유양식(원시 `CREATE TABLE` DDL)을 **DA검토 하네스**가 잘 변환하고 검사하는지
end-to-end로 확인하기 위한 테스트 데이터셋입니다.

## 무엇이 들어있나

| 파일 | 내용 | 기대 결과 |
|---|---|---|
| `ddl1_고객.sql` | TSCUSCA01 (고객기본) | ✅ 통과 |
| `ddl2_대출.sql` | TXLONBA01 — 테이블명 X·금액길이99·임시메모 | ❌ 반송 3건 + 감사컬럼 경고 |
| `ddl3_카드.sql` | TSCRDBB01 (카드상품) | ✅ 통과 |
| `ddl4_외환.sql` | TSFXDAC01 — 영문불일치·PK없음 | ❌ 반송 2건 |

`_reference/*.변환.yaml` = **정답지**. 에이전트가 변환한 결과를 이것과 비교해
"변환이 잘 됐는지" 확인하는 용도입니다. (시연 시 직접 만든 변환물과 대조)

DDL은 `-- 한글명 / 인포타입` 주석 규약으로 한글명·인포타입을 표기합니다.

## 전체 흐름 (5단계)

```
① 자유양식 DDL  →  ② LLM(에이전트) 변환  →  ③ 변환 확인  →  ④ gate 검사  →  ⑤ 정상/오류 확인
```

### ① 자유양식 DDL 준비
이 폴더의 `ddl*.sql` 이 원시 설계도입니다. (또는 본인 DDL을 넣어도 됨)

### ② LLM(에이전트) 변환 — Claude Code 에이전트가 수행
> ⚠️ DDL→INPUT(yaml) 변환은 **CLAUDE.md를 읽는 Claude Code 에이전트**가 합니다.
> `convert-csv.py`는 고정 CSV 전용, `convert-llm.py`는 내부 LLM 연결용 stub이라
> SQL DDL은 처리하지 못합니다. 따라서 이 단계는 CLI 명령이 아니라 **에이전트에게 요청**합니다.

Claude Code에서 da-review-kit을 열고:
```
input/freeform/ddl/ddl2_대출.sql 를 DA검토 해줘
```
에이전트가 CLAUDE.md → CONVERT-GUIDE.md 규약대로 `physical_name·columns(korean/english/
infotype/typelength/pk)` 를 추출해 INPUT yaml을 만듭니다.

### ③ 변환 확인
에이전트 변환물을 `_reference/ddlN_*.변환.yaml` 과 비교 → 컬럼·인포타입·pk 누락/오류 없는지.

### ④ gate 검사 (결정적, CLI)
```bash
bash gates/check-physical.sh  <변환된.yaml>
bash gates/check-attribute.sh <변환된.yaml>   # 속성명이 있을 때
```

### ⑤ 정상/오류 확인
ddl1·ddl3 → ✅ 통과 / ddl2·ddl4 → ❌ 반송(사유) 가 나오면 흐름 정상.

## 빠른 검증 (정답지로 게이트만 바로 실행)
변환 단계를 건너뛰고 게이트 동작만 보고 싶으면 `_reference` 변환물로 바로:
```bash
for f in input/freeform/ddl/_reference/*.변환.yaml; do
  echo "===== $f ====="; bash gates/check-physical.sh "$f"; echo
done
```
