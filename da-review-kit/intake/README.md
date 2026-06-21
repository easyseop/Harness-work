# intake — DA검토 앞단 (게이트 실행 전 준비)

게이트(검사)는 **결정적**으로 그대로 두고, 그 **앞단**에만 준비 작업을 둔다.

```
원본 설계도(비정형)
   → [① LLM 변환]  → [② check-ready(표준여부·충분성)]  → 정형 INPUT
   → 기존 게이트(check-physical / attribute / instance-code)  ← 그대로
```

## ① LLM 변환 (hook — 틀, 정식 연결은 내부 LLM)

- 입력: 실제 설계도(ERD 엑셀/CSV/텍스트 등 비정형)
- 출력: `schemas/db-design.schema.json` 형식의 INPUT yaml
- 규칙:
  - LLM은 **변환만** 한다 (검사·판정 아님).
  - 변환 결과는 **반드시 스키마로 검증**해서 형식 보장(환각 방지).
  - **내부망 LLM** 사용 (설계도는 내부정보).
  - 표준여부는 LLM이 **추정만**, 확정은 ②에서 사람/스키마목록으로.
- 연결 지점: `intake/llm-convert`(미구현 자리) — 내부 LLM API로 교체.

## ② check-ready (결정적, 구현됨)

표준여부 확인 + 정보 충분성 점검.

```bash
bash intake/check-ready.sh <candidate-input.yaml>
# ✅ 준비 완료 → 게이트 실행 가능
# ❌ 보완 필요 → 부족 정보·표준여부 확인 안내
```

- 표준여부: `table.standard` → `schema∈standard_schemas` → 기본값(미명시는 확인 권고)
- 충분성: 표준 테이블이 `korean/english/infotype` + PK 를 갖췄나
- 통과(exit 0) 후 게이트 실행. 부족(exit 1)이면 보완.
