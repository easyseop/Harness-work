# da-review 하네스 — 에이전트 실행 대본 (CLAUDE.md)

> 사용자가 "DA검토 해줘"라고 하면, **이 대본대로** 사전준비→INPUT→게이트→결과까지 진행한다.
> 검사(gate)는 결정적 스크립트로 실행하고, 에이전트는 **오케스트레이션(질문·변환·실행·보고)** 만 한다.

## 역할 경계 (불변)
- **검사는 절대 추정으로 하지 않는다.** 항상 `gates/*.sh` 를 실행해 결과(JSON/exit)를 근거로 삼는다.
- **표준여부는 사람 지정/목록** 기반. 에이전트가 추정하지 않는다.
- **변환 시 없는 값을 창작하지 않는다.** 모르면 사용자에게 묻는다.

## 진행 절차

### 1) 표준 테이블 확인 (사전, 설계도 전)
- `intake/standard-tables.yaml` 가 있으면 그 목록을 쓴다.
- 없거나 불명확하면 **질문**: "이번에 검토할 **표준 테이블 목록**을 알려주세요. (운영 DB에 들어갈 표준 대상만)"
- 목록에 없는 테이블은 **비표준 → 검토 제외**.

### 2) 설계도 수집 + 형태 확인
- **질문**: "설계도를 주세요. **고정 양식(엑셀/CSV)** 인가요, **자유 형식**인가요?"

### 3) 변환 → 정형 INPUT (`schemas/db-design.schema.json` 형식)
- **매핑 규칙은 `intake/CONVERT-GUIDE.md` 를 그대로 따른다.** (설계도 항목 → INPUT 필드)
- **고정 CSV/엑셀** → `python3 intake/convert-csv.py <csv> intake/standard-tables.yaml > input.yaml`
- **자유 형식** → 에이전트가 CONVERT-GUIDE 매핑대로 스키마 형식으로 변환(없는 값은 빈칸, standard 판단 금지). 핵심: 인포타입은 "도메인+길이"(예: 년월일8).
- 인스턴스코드 정의서면 `schemas/instance-code.schema.json` 형식으로.

### 4) 부족 정보 점검
- **방법 A(권장·단순)**: 곧장 게이트 실행 후, 결과 findings의 **`category`** 로 구분
  - `category: "missing"` (인포타입 미기재·누락 등) → **사용자에게 질문**해 보완
  - `category: "violation"` (표준 위반) → 6)에서 반송사유로 보고
- **방법 B(사전)**: `bash intake/check-ready.sh input.yaml` 로 먼저 부족 점검 후 질문 → 채워지면 게이트.
- (게이트가 부족 정보도 잡으므로 check-ready는 선택. 부족(missing)은 묻고, 위반(violation)은 보고.)

### 5) 게이트 실행 (결정적 검사)
- DB설계서: `bash gates/check-physical.sh input.yaml` + `bash gates/check-attribute.sh input.yaml`
- 인스턴스코드 정의서: `bash gates/check-instance-code.sh input.yaml`
- 결과 JSON 필요 시 `DA_OUT=result.json` 지정.

### 6) 결과 보고
- 게이트의 `status`·`findings` 를 사람이 읽기 쉽게 정리:
  - 통과면 "✅ 통과", 반송이면 위반 목록(대상·사유)과 **권고(어떻게 고칠지)**.
  - 근거는 반드시 게이트 출력. 임의로 판정 추가 금지.

## 질문 템플릿 (사전준비)
1. "검토할 **표준 테이블 목록**을 알려주세요." (standard-tables.yaml 없을 때)
2. "설계도 형태는? **엑셀/CSV(고정)** vs **자유형식**"
3. (부족 시) "{테이블}.{컬럼} 의 {항목}이(가) 없습니다. 알려주세요."

## 한 줄 요약
표준목록 확인 → 설계도 변환(INPUT) → 사전점검(부족하면 질문) → **게이트 실행(결정적)** → 결과 보고.
에이전트는 묻고 변환하고 실행·정리, **판정은 게이트가** 한다.
