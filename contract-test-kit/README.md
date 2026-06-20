# contract-test 채우기 키트

MVP 하네스 **contract-test**(계약 검증)를 완성하기 위한 키트입니다.
처음이면 `MANUAL.md` 부터 읽으세요. 용어는 `core/GLOSSARY.md`.

## 이 하네스가 하는 일 (한 줄)

> 코드가 솔루션 카드(계약)의 약속 — 입력 필드·출력·오류코드 — 을 실제로 지키는지
> 대역(Mock) 테스트로 검증한다. 실제 내부 시스템엔 연결하지 않는다.

## 왜 필요한가 (쉽게)

계약(메뉴판)만 있고 코드가 그대로 동작하는지 확인 안 하면, 내부망에 들여온 뒤에야
"오류 처리가 빠졌다"를 발견합니다. 이 하네스가 그걸 **반입 전에** 잡습니다.

## 폴더 안에 뭐가 있나

| 파일 | 누가 | 설명 |
|---|---|---|
| `MANUAL.md` | (읽기) | **처음 보는 사람용 매뉴얼** — 여기부터 |
| `policy.yaml` | 🟡 당신/담당자 | 어디까지 덮어야 통과인지 규칙 |
| `test-spec.template.yaml` | 🟡 개발자 | 테스트 케이스를 적는 양식 |
| `test-spec.messenger.example.yaml` | 🟢 예시 | 메신저 계약을 케이스 10개로 옮긴 샘플 |
| `gates/check-contract-coverage.sh` | 🟢 | 오류코드·정상·누락을 다 덮었는지 검사 |
| `manifest.yaml` | 🟢 | 하네스 자기소개 파일 |
| `FILL-GUIDE.md` | (읽기) | 케이스 적는 설명서 |
| `SAFE-OR-NOT.md` | 🔴 (읽기) | 안전수칙 |

## 빠른 시작

```bash
gates/check-contract-coverage.sh \
    test-spec.messenger.example.yaml \
    ../internal-solution-kit/solution-card.messenger.yaml
```
