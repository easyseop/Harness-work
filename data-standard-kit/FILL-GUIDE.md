# 채우기 설명서 (FILL-GUIDE) — data-standard

새 데이터(테이블/데이터셋/파이프라인)를 만들 때, `data-contract.template.yaml` 을 복사해 1장씩 채웁니다.
데이터 분석/모델링 경험이 있으면 익숙한 내용일 거예요.

---

## dataset — 데이터 기본 정보

| 칸 | 뜻 | 예시 |
|---|---|---|
| `name` | 표준 이름 (이름 규칙 통과 필요, 영문 스네이크) | `deposit_balance_daily` |
| `type` | 종류 | `table` / `dataset` / `pipeline` |
| `owner_role` | 데이터 책임 **역할** (사람 이름 X) | `데이터플랫폼팀` |
| `classification` | 등급 | `공개` / `내부` / `민감` / `극비` |
| `retention_days` | 보관 기간(일) | `1825` (5년) |
| `description` | 한 줄 설명 | `일별 예금 잔액 집계` |

## columns — 컬럼 목록

각 컬럼마다:
- `name`: 기술 이름 (영문 스네이크). 예: `account_id`
- `type`: 자료형. 예: `string` / `number` / `date` / `decimal`
- `standard_term`: 연결되는 **표준 용어**(한글 가능). 예: `계좌식별자`
- `nullable`: 빈 값 허용 여부. `true` / `false`
- `description`: 설명

💡 `name`(기술 이름)과 `standard_term`(업무 표준 용어)을 나눠 적는 게 핵심입니다.
이게 나중에 "용어는 같은데 컬럼명이 제각각"인 문제를 막아 줍니다.

## lineage — 흐름

- `inputs`: 이 데이터가 어디서 오는지 (출처 이름들)
- `outputs`: 이 데이터를 누가 쓰는지

흐름을 적어 두면, 나중에 원천이 바뀔 때 영향 범위를 바로 알 수 있습니다.

---

## 이름 규칙은 어디서 정하나

`policy.yaml` 의 `naming` 에 있습니다. 기본값은 "소문자·숫자·밑줄"(스네이크 케이스)입니다.
조직 규칙이 다르면(예: 접두사 `tb_` 필수) `policy.yaml` 을 고치면 됩니다.

## 다 채운 뒤 — 검사 돌리기

```bash
gates/check-naming.sh data-contract.example.yaml
gates/check-metadata-complete.sh data-contract.example.yaml
```
