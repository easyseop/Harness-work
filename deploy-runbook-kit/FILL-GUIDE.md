# 채우기 설명서 (FILL-GUIDE) — deploy-runbook

`runbook.template.yaml` 을 복사해 배포 절차를 단계별로 적습니다.
실제 예시는 `runbook.messenger.example.yaml`.

---

## runbook — 기본 정보

| 칸 | 뜻 | 예시 |
|---|---|---|
| `project` | 프로젝트 식별값 | `PRJ-2026-014` |
| `owner_role` | 배포 책임 역할 | `운영팀` |

## 5단계 (모두 필수, 빈 목록이면 막힘)

| 단계 | 무엇을 적나 |
|---|---|
| `precheck` | 배포 전에 확인할 것 (반입 통과·설정 주입·IP 등록 등) |
| `deploy` | 배포 절차를 **순서대로** |
| `verify` | 배포 후 정상 동작 확인 항목 |
| `rollback` | 문제 시 되돌리는 절차 (**반드시** 필요) |
| `contacts` | 비상 연락 (역할 기준) |

## contacts — 연락처 (역할로만)

```yaml
contacts:
  - role: 운영팀 당직        # 실제 이름·전화번호 X
    when: 배포 중 장애 1차
```

## 실제 값은 어떻게?

서버 주소·접속코드는 절대 적지 않습니다. 빈 자리·표현으로 적습니다.
- O: "설정 빈 자리(`${MESSENGER_HOST}`)가 주입되었는지 확인"
- X: "`http://10.20.30.40` 로 접속"

## 다 적은 뒤 — 검사 돌리기

```bash
gates/check-runbook-complete.sh      runbook.yaml
gates/check-no-secrets-in-runbook.sh runbook.yaml
```
