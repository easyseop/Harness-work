# da-review 입출력 형식 (고정)

> 이 문서가 정의하는 **INPUT/OUTPUT 형식만** 사이트(은행)에 맞게 바뀔 수 있고,
> **게이트 로직·META 규칙·스키마 구조는 바뀌지 않는다.** (adapter 경계)

## INPUT (검토대상) — 2종

| 산출물 | 파일 | 스키마 | 검사 게이트 |
|---|---|---|---|
| DB설계서 | `input/*.yaml` | `schemas/db-design.schema.json` | check-physical, check-attribute |
| 인스턴스코드 정의서 | `input/*.yaml` | `schemas/instance-code.schema.json` | check-instance-code |

- 실제 산출물(erwin export, 엑셀 등)은 **adapter**가 위 스키마 형식으로 변환해 넣는다.
- DB설계서 핵심 필드: `tables[].columns[] = {korean, english, attribute?, infotype, typelength?, pk, nullable, std?}`
- 인스턴스코드 핵심: `instance_names[]`(시트1) + `code_values[]`(시트2)

## OUTPUT (검사 결과) — 고정 1종

- 스키마: `schemas/da-review-result.schema.json`
- 모든 게이트가 **동일 형식**으로 출력 → 테스트는 이 형식을 비교한다.
- 생성 방법: 환경변수 `DA_OUT=<경로>` 지정 시 그 경로에 JSON 결과 파일 작성. (미지정 시 사람용 텍스트만 출력, exit code는 동일)

```bash
DA_OUT=out/result.json bash gates/check-physical.sh input/db-design.example.yaml
```

결과 예시:
```json
{
  "harness": "da-review",
  "gate": "check-physical",
  "target": "input/review-target.bad.yaml",
  "project": "고객부가_PJT",
  "status": "failed",
  "summary": { "errors": 5, "warnings": 0 },
  "findings": [
    { "severity": "error", "message": "[TXDPSAA01] 테이블명이 명명규칙에 안 맞음 ..." }
  ],
  "generated_at": "2026-06-20T08:28:38"
}
```

- `status`: `passed` | `failed` (게이트 exit code와 일치: passed=0, failed=1)
- `findings[].severity`: `error`(반송) | `warning`(경고, 통과)
