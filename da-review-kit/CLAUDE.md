# da-review 하네스 — 에이전트 실행 대본 (CLAUDE.md)

> 사용자가 "DA검토 해줘"라고 하면 **이 대본대로** 진행한다.
> 검사(gate)는 결정적 스크립트로 실행하고, 에이전트는 **오케스트레이션(질문·변환·실행·보고)** 만 한다.
> (이 파일은 da-review-kit 안에서만 쓰는 독립 대본 — 다른 하네스와 무관)

## 역할 경계 (불변)
- **검사는 추정으로 하지 않는다.** 항상 `gates/*.sh` 실행 결과(JSON/exit)를 근거로.
- **표준여부 = 사람 지정 목록**(`intake/standard-tables.yaml`)을 **기계적으로 적용**. 에이전트(LLM)가 추정하지 않는다.
- **변환 시 없는 값 창작 금지.** 모르면 빈칸 두고 사용자에게 묻는다.

## 0) 산출물 종류 먼저 판별
- **DB설계서** (테이블/컬럼)  →  [A] 흐름
- **인스턴스코드 정의서** (업무인스턴스명+코드값 2시트)  →  [B] 흐름
- 모호하면 질문: "검토할 산출물이 **DB설계서**인가요, **인스턴스코드 정의서**인가요?"

---

## [A] DB설계서 흐름

### A1) 표준 테이블 확인 (설계도 전)
- `intake/standard-tables.yaml` 있으면 그 목록 사용. 없으면 질문: "검토할 **표준 테이블 목록**을 알려주세요."
- 목록은 **기계적으로** 각 테이블 `standard`에 반영(추정 아님). 목록에 없으면 비표준 → 검토 제외.

### A2) 설계도 수집 + 형태 확인
- 질문: "설계도가 **고정 양식(엑셀/CSV)** 인가요, **자유 형식**인가요?"

### A3) 변환 → INPUT (`schemas/db-design.schema.json` 형식)
- 매핑은 **`intake/CONVERT-GUIDE.md`** 를 따른다. 인포타입은 "도메인+길이"(예: 년월일8).
- 고정 CSV/엑셀 → `python3 intake/convert-csv.py <csv> intake/standard-tables.yaml > input.yaml`
- 자유 형식 → **에이전트가 직접** CONVERT-GUIDE대로 변환(없는 값 빈칸, standard 판단 금지).
  (비-에이전트 자동화가 필요하면 `intake/convert-llm.py` 의 call_llm 연결)

### A4) 사전점검 — `check-ready` 먼저
- `bash intake/check-ready.sh input.yaml`
- 부족(❌)이면 사용자에게 **선택지 제시**(AskUserQuestion):
  - [1] 부족 정보 채우기(권장) → 질문해 채운 뒤 재점검
  - [2] 부족한 채로 게이트 실행 → A5로 (부족분은 `category=missing`로 보고)
  - [3] 해당 테이블 비표준 제외 → `standard:false` 처리 후 진행
  - [4] 중단
- 준비완료(✅)면 A5로.

### A5) 게이트 실행 (결정적)
- `bash gates/check-physical.sh input.yaml`  +  `bash gates/check-attribute.sh input.yaml`
- 결과 JSON 필요 시 `DA_OUT=result.json`.

→ 보고(공통) 로.

---

## [B] 인스턴스코드 정의서 흐름
(표준 테이블 개념 없음. 정보 충분성은 게이트가 직접 잡음.)

### B1) 설계도 수집 + 형태 확인 (고정/자유)
### B2) 변환 → INPUT (`schemas/instance-code.schema.json` 형식)
- 2시트: `instance_names`(업무인스턴스명정의서) + `code_values`(업무인스턴스코드정의서). CONVERT-GUIDE 참고.
### B3) 게이트 실행
- `bash gates/check-instance-code.sh input.yaml`

→ 보고(공통) 로.

---

## 결과 보고 (공통)
게이트 출력(`status`·`findings`)을 사람이 읽기 쉽게 정리. **근거는 게이트 출력뿐, 임의 판정 추가 금지.**
- 통과 → "✅ 통과".
- 반송 → findings를 **category로 나눠** 보고:
  - `category=missing` (정보 부족) → "이 정보를 채워야 함" + 질문/보완 안내
  - `category=violation` (표준 위반) → 대상(`scope`)·사유(`message`)·권고(고치는 법) 정리

## 질문 템플릿
1. "산출물이 DB설계서 vs 인스턴스코드 정의서?"
2. "(DB설계서) 표준 테이블 목록은?" / "설계도 형태는 고정(엑셀/CSV) vs 자유?"
3. (부족 시) "{테이블}.{컬럼} 의 {항목}이 없습니다. 알려주세요."

## 한 줄 요약
산출물 종류 판별 → (DB설계서) 표준목록·변환·사전점검(선택지)·게이트 / (인스턴스코드) 변환·게이트 → 결과 보고.
**판정은 게이트가, 에이전트는 묻고·변환하고·실행·정리.**
