# import-gate 채우기 키트

MVP 하네스 **import-gate**(반입 관문)를 완성하기 위한 키트입니다.
처음이면 `MANUAL.md` 부터 읽으세요. 용어는 `core/GLOSSARY.md`.

## 이 하네스가 하는 일 (한 줄)

> 반입(외부망→내부망) 직전 마지막 관문. 반입 묶음이 다 모였는지, 필수 증거가 모두 통과했는지,
> 만든 사람 ≠ 승인한 사람인지, 예외 승인이 만료되지 않았는지 검사한다.

## 왜 필요한가 (쉽게)

이 관문 없이 반입하면, 검사를 건너뛰거나 한 사람이 혼자 통과시키는 사고가 납니다.
이 하네스가 **출국 심사대**처럼 마지막에 모든 걸 확인합니다. 가장 엄격해서 우회 불가입니다.

## 폴더 안에 뭐가 있나

| 파일 | 누가 | 설명 |
|---|---|---|
| `MANUAL.md` | (읽기) | **처음 보는 사람용 매뉴얼** — 여기부터 |
| `policy.yaml` | (거버넌스 소유) | 필수 구성요소·역할분리·예외규칙 |
| `bundle-manifest.template.yaml` | 🟡 반입 담당자 | 반입 묶음을 적는 양식 |
| `bundle-manifest.messenger.example.yaml` | 🟢 예시 | 메신저 모듈 반입 묶음 샘플 |
| `gates/check-bundle-complete.sh` | 🟢 ★ | 묶음 완성·증거 통과 검사 |
| `gates/check-roles-and-waivers.sh` | 🟢 ★ | 역할분리·예외만료 검사 |
| `manifest.yaml` | 🟢 | 하네스 자기소개 파일 |
| `FILL-GUIDE.md` | (읽기) | 묶음 채우는 설명서 |
| `SAFE-OR-NOT.md` | 🔴 (읽기) | 안전수칙 |

## 빠른 시작

```bash
gates/check-bundle-complete.sh   bundle-manifest.messenger.example.yaml
gates/check-roles-and-waivers.sh bundle-manifest.messenger.example.yaml
```
