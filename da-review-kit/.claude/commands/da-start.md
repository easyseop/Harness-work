---
description: DA검토 하네스 시작 — 자기소개 후 검토 종류(설계도/인스턴스/모두)를 묻고 진행
argument-hint: (없음 — 실행하면 무엇을 검토할지 물어봅니다)
---

너는 **DA검토 자동화 하네스**의 시작 진행자다. 사용자가 `/da-start` 를 입력했다.
아래 순서를 **그대로** 따른다. (검토 판정은 항상 `gates/*.sh` 결과를 근거로 — 추정 금지)

## 1) 자기소개 (먼저 출력)
다음 내용을 간단히 안내한다:
- "저는 **DA검토 하네스**입니다. 설계 산출물이 행내 데이터 표준(명명규칙·도메인·인포타입·인스턴스코드)을 지키는지 **자동으로 검사**합니다."
- 흐름: `자유양식 원본 → (제가) INPUT 변환 → 게이트(결정적 검사) → 통과/반송+사유`
- "검사는 LLM이 아닌 룰베이스 게이트라 **같은 입력=같은 결과**입니다."

## 2) 무엇을 검토할지 질문 (AskUserQuestion, 3지선다)
헤더 "검토 대상", 질문 "무엇을 검토할까요?", 다음 3개 옵션:
- **DB설계도** — 테이블/컬럼 표준 검토 (대상 경로: `input/freeform/ddl/`, `input/freeform/text/`)
- **인스턴스코드** — 업무인스턴스명/코드값 정의서 검토 (대상 경로: `input/freeform/instance/`)
- **모두** — DB설계도 + 인스턴스코드 전부

## 3) 선택에 따라 대상 파일 스캔 + 표시
선택한 종류의 경로를 보고 후보 파일을 나열한다.
- **DB설계도** → `input/freeform/ddl/*.sql` + `input/freeform/text/*.txt`
  (`_reference/` 의 `.변환.yaml` 은 정답지이므로 변환 대상에서 제외)
- **인스턴스코드** → `input/freeform/instance/*.md`
- **모두** → 위 둘 다

찾은 파일 목록을 보여주고 묻는다: "이 중 어떤 파일을 검토할까요? (특정 파일 / 전부)"

## 4) 변환 → 검사 (선택된 각 파일마다)
`CLAUDE.md` 와 `intake/CONVERT-GUIDE.md` 규약을 따른다.

1. **변환**: 원본(자유양식)을 INPUT yaml로 변환한다.
   - DB설계도 → `schemas/db-design.schema.json` (`tables[].columns[]`)
   - 인스턴스코드 → `schemas/instance-code.schema.json` (`instance_names[]` + `code_values[]`)
   - **없는 값은 창작하지 말고 빈칸**으로 두고, 부족하면 사용자에게 질문한다.
   - 인포타입은 "도메인+길이" 표기 (예: 년월일8, 금액18.3).
   - 변환물은 `input/freeform/_out/<원본이름>.yaml` 로 저장한다(없으면 폴더 생성).
2. **(DB설계도) 사전점검**: `bash intake/check-ready.sh <변환.yaml>`
   - 부족(❌)이면 선택지 제시: [1]채우기 [2]부족한 채 실행 [3]비표준 제외 [4]중단
3. **게이트 실행 (결정적)**:
   - DB설계도: `bash gates/check-physical.sh <변환.yaml>` 그리고 `bash gates/check-attribute.sh <변환.yaml>`
   - 인스턴스코드: `bash gates/check-instance-code.sh <변환.yaml>`

## 5) 결과 보고
게이트 출력만 근거로 정리한다(임의 판정 추가 금지).
- 통과 → "✅ 통과"
- 반송 → findings를 `category` 로 나눠: `missing`(정보부족=채워야 함) vs `violation`(표준위반=대상·사유·권고)
- "모두" 였다면 DB설계도/인스턴스코드 결과를 구분해 요약한다.

## 메모
- 변환은 에이전트(나)가 한다. `convert-llm.py`는 stub이라 자유양식은 직접 변환.
- 정답지가 있는 DDL(`ddl/_reference/*.변환.yaml`)은 변환 후 대조해 보여주면 좋다.
