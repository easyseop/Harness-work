# 채우기 설명서 (FILL-GUIDE) — contract-test

`test-spec.template.yaml` 을 복사해 테스트 케이스를 적습니다.
실제 예시는 `test-spec.messenger.example.yaml`.

---

## test_spec — 기본 정보

| 칸 | 뜻 | 예시 |
|---|---|---|
| `for_solution` | 어떤 솔루션 카드인지 (별칭) | `messenger` |
| `capability` | 검증할 기능 이름 | `send_memo` |
| `owner_role` | 책임 역할 | `내부플랫폼팀` |

## cases — 케이스 1개당

| 칸 | 뜻 |
|---|---|
| `id` | 케이스 식별값. 예: `happy-1` |
| `type` | `happy`(정상) / `error`(오류) / `missing-field`(필수누락) |
| `given` | 입력 (가짜 값만!) |
| `expect.result_code` | 기대 결과 코드. 예: `"0"`, `"34"` |
| `note` | 설명 |

---

## 케이스를 어떻게 뽑나 (쉬운 방법)

솔루션 카드의 `errors` 목록을 그대로 케이스로 옮기세요.

1. 정상 케이스 1개 (`type: happy`, `result_code: "0"`)
2. 카드 `errors` 의 코드마다 1개씩
3. 필수 입력(required:true)마다 "그걸 뺀" 누락 케이스

이렇게만 하면 게이트의 커버리지 요건을 채웁니다.

## 다 적은 뒤 — 검사 돌리기

```bash
gates/check-contract-coverage.sh <test-spec.yaml> <solution-card.yaml>
```
