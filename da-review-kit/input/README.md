# input/ — 입력 산출물 디렉터리 안내

경로가 헷갈리지 않도록 용도별로 3곳으로만 둡니다.

| 위치 | 용도 | 누가 참조 |
|---|---|---|
| `freeform/` | **자유양식 변환 시연용** (DDL·텍스트·인스턴스 원본) — 실제로 클론해서 테스트할 때 사용 | 에이전트 변환 → 게이트 |
| `*.yaml` (루트) | **게이트 기본/골든 테스트 입력** (예시 INPUT) | 게이트 기본값·`tests/cases.yaml`·README/FORMATS |
| `_archive/` | **안 쓰는 옛 테스트** (mock·sets) — 보관만, 평소엔 무시 | 없음 |

## 루트의 예시 INPUT (functional — 옮기지 말 것)
- `review-target.good.yaml` / `review-target.bad.yaml` — check-physical·check-attribute 기본 입력
- `instance-code.good.yaml` / `instance-code.bad.yaml` — check-instance-code 기본 입력
- `db-design.example.yaml` — README/FORMATS 예시

> `run-all.sh` 는 `input/` **바로 아래** yaml만 검사합니다(하위 폴더·`_archive` 제외).
> 자유양식 시연은 `freeform/README.md` 참고.
