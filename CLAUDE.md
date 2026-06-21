# Harness-work — 에이전트 안내 (루트 CLAUDE.md)

이 저장소는 **데이터 표준 하네스 모음**입니다. 이 파일은 **AI 에이전트(Claude Code)** 가
저장소를 열었을 때 읽는 진입 안내입니다. (게이트 스크립트는 이 파일을 읽지 않습니다.)

## 작업별 진입점

- **DA 검토** (DB설계서 / 인스턴스코드 정의서가 표준을 지키는지 검토)
  → **`da-review-kit/CLAUDE.md` 를 읽고 그 절차대로 진행**한다.
    (표준목록 확인 → 설계도 변환 → 사전점검(부족 시 선택지) → 게이트 실행 → 결과 보고)

- **데이터 품질** (적재 값 검사: date8 유효성·유효식별자 등)
  → `data-standard-kit/`

- **공통 규칙·불변식** → `core/CLAUDE.md`, `core/ARCHITECTURE_INVARIANTS.md`

## 공통 원칙 (모든 하네스)

- **검사(게이트)는 결정적 스크립트로 실행**한다. 추정으로 판정하지 않는다.
- 에이전트는 **질문·변환·실행·결과정리(오케스트레이션)** 만 한다.
- 표준/비표준은 **사람 지정/목록** 기반. LLM 추정 금지.
- 변환 시 없는 값 창작 금지(빈칸 두고 사용자에게 질문).

## "DA검토 시작" 하면
1. `da-review-kit/CLAUDE.md` 절차를 따른다.
2. 표준 테이블 목록 확인 → 설계도 받기 → INPUT 변환(`intake/CONVERT-GUIDE.md`) →
   `intake/check-ready.sh` 사전점검 → `gates/*.sh` 실행 → findings(category/scope/suggestion) 보고.
