# deploy-runbook 채우기 키트

하네스 **deploy-runbook**(배포 안내서)를 완성하기 위한 키트입니다.
처음이면 `MANUAL.md` 부터 읽으세요. 용어는 `core/GLOSSARY.md`.

## 이 하네스가 하는 일 (한 줄)

> 내부망 배포 절차를 안내서로 표준화한다. 사전점검·배포·검증·롤백·비상연락 단계가
> 빠짐없이 있고, 민감정보가 섞이지 않았는지 검사한다.

## 폴더 안에 뭐가 있나

| 파일 | 누가 | 설명 |
|---|---|---|
| `MANUAL.md` | (읽기) | **처음 보는 사람용 매뉴얼** |
| `policy.yaml` | (운영팀) | 필수 단계·롤백 요구·금지 패턴 |
| `runbook.template.yaml` | 🟡 배포 담당 | 배포 안내서 양식 |
| `runbook.messenger.example.yaml` | 🟢 예시 | 메신저 모듈 배포 안내서 샘플 |
| `gates/check-runbook-complete.sh` | 🟢 | 필수 단계·롤백·검증 유무 검사 |
| `gates/check-no-secrets-in-runbook.sh` | 🟢 ★ | 안내서 비밀값 섞임 검사 |
| `manifest.yaml` | 🟢 | 하네스 자기소개 파일 |
| `FILL-GUIDE.md` | (읽기) | 안내서 작성 설명서 |
| `SAFE-OR-NOT.md` | 🔴 (읽기) | 안전수칙 |

## 빠른 시작

```bash
gates/check-runbook-complete.sh      runbook.messenger.example.yaml
gates/check-no-secrets-in-runbook.sh runbook.messenger.example.yaml
```
