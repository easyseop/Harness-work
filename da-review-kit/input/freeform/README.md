# 자유양식 데이터셋 — 변환 시연용

DA검토 하네스가 **제각각인 원본 설계 산출물**을 INPUT 규격으로 잘 변환하는지
확인하기 위한 자유양식 모음입니다.

## 구성

| 경로 | 형태 | 정답지(예상결과) |
|---|---|---|
| `ddl/*.sql` | DDL(`CREATE TABLE`) | 있음 (`ddl/_reference/`) |
| `text/*.txt` | 텍스트형 테이블 설계도 (서술·메모·메일·혼합) | **없음** |
| `instance/*.md` | 인스턴스코드 정의서 (2시트 표형식) | **없음** |

> 초기 예시(`설계도1/2`)는 테스트 방해 방지를 위해 `../../docs/변환예시/` 로 옮겼습니다.
> `text/`·`instance/` 는 **변환 결과를 일부러 넣지 않았습니다.**
> 에이전트(또는 사용자)가 변환한 결과를 가지고 판단/검증하는 용도입니다.

## 사용 흐름

```
자유양식 원본  →  ② LLM(에이전트) 변환  →  ③ 변환 확인  →  ④ gate 검사  →  ⑤ 정상/오류 확인
```

- **②변환**: Claude Code 에이전트가 `CLAUDE.md` → `intake/CONVERT-GUIDE.md` 규약대로
  INPUT yaml(`schemas/db-design.schema.json` 또는 `instance-code.schema.json`)로 변환.
  (`convert-csv.py`=고정 CSV 전용, `convert-llm.py`=내부 LLM stub → SQL/텍스트는 에이전트가 변환)
- **④검사 (CLI, 결정적)**:
  - DB설계: `bash gates/check-physical.sh <yaml>` / `bash gates/check-attribute.sh <yaml>`
  - 인스턴스코드: `bash gates/check-instance-code.sh <yaml>`

## 텍스트형 설계도 (text/)

| 파일 | 형태 |
|---|---|
| `text1_예금_서술형.txt` | 문장 서술형 |
| `text2_직원_메모형.txt` | 불릿 메모형 |
| `text3_상품_대화형.txt` | 메일/질문형 |
| `text4_채널_혼합형.txt` | 정렬 안 된 혼합 메모 |

## 인스턴스코드 (instance/)

| 파일 | 형태 |
|---|---|
| `ic1_계좌상태.md` | 2시트 표형식 |
| `ic2_명명위반.md` | 2시트 표형식 |
| `ic3_거래.md` | 2시트 표형식 |
| `ic4_코드값위반.md` | 2시트 표형식 |
