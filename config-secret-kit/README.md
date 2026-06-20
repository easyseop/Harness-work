# config-secret 채우기 키트

MVP 하네스 **config-secret**(설정·비밀값 주입)을 완성하기 위한 키트입니다.
처음이면 `MANUAL.md`(매뉴얼)부터 읽으세요. 용어는 `core/GLOSSARY.md`.

## 이 하네스가 하는 일 (한 줄)

> 코드가 쓰는 **빈 자리**(`${MESSENGER_HOST}` 등)를 목록으로 선언하고,
> 진짜 값(HOST·접속코드·비밀번호)은 외부망에 절대 박히지 않게 하며,
> 내부망 반입 시점에만 주입되도록 강제한다.

## 왜 필요한가 (쉽게)

외부망에서 개발하면서 진짜 서버 주소·접속코드를 코드에 박으면 유출 사고가 납니다.
그래서 **진짜 값 대신 빈 자리로 짜 두고**, 나중에 내부망에서 값만 꽂습니다.
이러면 코드를 한 줄도 안 고치고 내부망에서 그대로 돌릴 수 있습니다.

## 폴더 안에 뭐가 있나

| 파일 | 누가 | 설명 |
|---|---|---|
| `MANUAL.md` | (읽기) | **처음 보는 사람용 매뉴얼** — 여기부터 |
| `policy.yaml` | 🟡 당신/담당자 | 값 종류·사는 곳·금지 패턴 등 규칙 |
| `binding.template.yaml` | 🟡 당신/담당자 | 빈 자리 1개를 적는 양식 |
| `binding.messenger.example.yaml` | 🟢 예시 | 사내 쪽지(messenger) 실제 예시 |
| `binding.schema.json` | 🟢 | 형식 자동 검사 규칙 |
| `gates/check-bindings-complete.sh` | 🟢 | 빈 자리 목록이 규칙을 지키는지 검사 |
| `gates/check-no-hardcoded-values.sh` | 🟢 ★ | 코드에 진짜 값 박힘 검사 (보안 핵심) |
| `manifest.yaml` | 🟢 | 하네스 자기소개 파일 |
| `FILL-GUIDE.md` | (읽기) | 채우는 설명서 |
| `SAFE-OR-NOT.md` | 🔴 (읽기) | 안전수칙 |

## 빠른 시작

```bash
# 1) 빈 자리 목록 검사
gates/check-bindings-complete.sh binding.messenger.example.yaml

# 2) 코드 폴더에 진짜 값이 박혔는지 검사
gates/check-no-hardcoded-values.sh ./src
```
