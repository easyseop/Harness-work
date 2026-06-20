# 채우기 설명서 (FILL-GUIDE) — oss-runtime-eol

`components.template.yaml` 에 쓰는 구성요소를 적습니다 (또는 SBOM 결과를 옮깁니다).
실제 예시는 `components.messenger.example.yaml`.

---

## components — 구조

| 칸 | 뜻 | 예시 |
|---|---|---|
| `project` | 프로젝트 식별값 | `PRJ-2026-014` |
| `generated_on` | 작성일 | `2026-06-16` |

## runtimes — 런타임 (언어/실행환경)

```yaml
- name: java
  version: 21        # 메이저 버전 (policy.yaml 의 java@21 과 짝)
```
`name@version` 이 `policy.yaml` 의 EOL 날짜표 키와 맞아야 검사됩니다.

## libraries — 라이브러리

```yaml
- name: spring-boot
  version: 3.2.1
  license: Apache-2.0   # SPDX 식별자 (Apache-2.0, MIT, BSD-3-Clause 등)
```

## 정책은 어디서 정하나

`policy.yaml` 에서:
- `licenses.allowed` / `licenses.denied` — 허용/금지 라이선스
- `eol.runtimes` — 런타임 EOL 날짜표
- `eol.warn_within_days` — 임박 경고 기준(기본 180일)

## 다 적은 뒤 — 검사 돌리기

```bash
gates/check-license.sh components.yaml
gates/check-eol.sh     components.yaml
```
