# 채우기 설명서 (FILL-GUIDE)

`solution-card.template.yaml` 을 복사해 **내부 시스템 1개당 카드 1장**을 채웁니다.
먼저 `SAFE-OR-NOT.md`(안전수칙)를 읽으세요.

---

## 1. solution — 시스템 기본 정보

| 칸 | 무슨 뜻 | 예시 |
|---|---|---|
| `alias` | 시스템 별칭(이름표). 실제 제품명·주소 아님 | `messenger` |
| `category` | 종류 | `communication`(쪽지·알림) / `api` / `file-transfer` / `auth` / `batch` |
| `owner_role` | 관리하는 **역할** 이름 (사람 이름 X) | `내부플랫폼팀` |
| `description` | 한 줄 설명 | `사내 직원에게 쪽지 알림을 보낸다` |

## 2. capabilities — 이 시스템으로 할 수 있는 기능

기능이 여러 개면 `- name:` 블록을 여러 개 둡니다. 각 기능마다:

- **input(넣는 것)**: 이 기능을 부를 때 넘기는 값들. 항목 이름·형식·설명.
- **output(나오는 것)**: 결과로 받는 값들.
- **errors(오류)**: 실패할 때 나올 수 있는 오류 코드와 그 뜻.
- **nonfunctional(약속)**:
  - `timeout_ms`: 몇 밀리초 안에 응답이 없으면 실패로 볼지 (예: `3000` = 3초)
  - `retry_max`: 실패하면 몇 번 다시 시도할지 (예: `2`)

💡 **잘 모르면**: 그 시스템을 실제로 쓰는 화면이나 안내문서를 떠올려, "무엇을 입력하면 무엇이 나오는지"만 적으면 됩니다. 내부 연결 방식은 몰라도 됩니다.

## 3. security — 안전 표시

- `forbidden_in_external_zone`: 이 시스템과 관련해 외부망에 두면 안 되는 것 (보통 `real_endpoint`, `secret`, `real_user_id` 그대로 두면 됨)
- `data_classification`: 가짜 데이터 등급. 보통 `no-customer-data`(고객정보 금지)

## 4. mode — 외부/내부에서 다루는 방식

| 칸 | 뜻 | 보통 값 |
|---|---|---|
| `internal_connection_type` | 내부에서 실제 연결 방식 | `api` / `mq` / `file` / `batch` |
| `external_development_mode` | 외부망 개발 방식 | `mock-only`(가짜 대체물로만) 가 가장 안전 |
| `internal_adapter_required` | 내부망에서 실제 연결 코드가 필요한가 | 보통 `true` |

## 5. verification — 무엇을 시험하나

- `external_tests`: 외부망 시험. 보통 `contract-test`(약속대로 동작) + `mock-fixture-test`(가짜로 시험)
- `internal_tests`: 내부망 시험. 보통 `adapter-smoke-test`(실제 연결 최소 확인)

---

## 다 채운 뒤 — 검사 돌리기

```bash
# 1) 실제 주소·비밀번호가 섞였는지 (가장 중요)
gates/check-no-internal-secrets.sh solution-card.example.yaml

# 2) 카드에 빈칸이 없는지
gates/check-contract-complete.sh solution-card.example.yaml
```
