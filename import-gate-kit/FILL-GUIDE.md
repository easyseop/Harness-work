# 채우기 설명서 (FILL-GUIDE) — import-gate

`bundle-manifest.template.yaml` 을 복사해 반입 묶음을 정리합니다.
실제 예시는 `bundle-manifest.messenger.example.yaml`.

---

## bundle — 기본 정보

| 칸 | 뜻 | 예시 |
|---|---|---|
| `project` | 프로젝트 식별값 | `PRJ-2026-014` |
| `version` | 반입 버전 | `1.0.0` |
| `created_on` | 작성일 | `2026-06-16` |

## items — 구성요소

각 항목에 경로를 적습니다. (해당 없으면 정책상 필수가 아닌 것만 비움)

| 항목 | 뜻 |
|---|---|
| `source` | 소스 코드 위치 |
| `lockfile` | 의존성 잠금 파일 |
| `sbom` | 구성요소 목록 |
| `contracts` | 솔루션 카드 위치 |
| `manifest` | 하네스 매니페스트 위치 |

## evidence — 증거 목록

앞 하네스들의 evidence id 를 그대로 옮기고 상태를 적습니다.

```yaml
- id: profile               # policy-profile
  status: passed
  required: true
- id: solution-contract     # internal-solution
  status: passed
  required: true
- id: binding               # config-secret
  status: passed
  required: true
- id: contract-test-report  # contract-test
  status: passed
  required: true
```

## attestation — 서명 (역할 분리)

| 칸 | 뜻 | 규칙 |
|---|---|---|
| `developer` | 만든 사람(역할) | |
| `verifier` | 검사한 사람(역할) | developer 와 다름 권장 |
| `approver` | 승인한 사람(역할) | **developer 와 반드시 다름** |

## waivers — 예외 승인 (없으면 `[]`)

예외가 필요하면 1건당 네 가지 모두 적습니다.

```yaml
waivers:
  - gate: check-allowed-tech-stack   # 어떤 검사를 우회
    reason: 임시 승인된 신규 라이브러리
    approved_by: 거버넌스팀           # 누가 승인
    expires_on: "2026-09-30"          # 만료일 (필수, 지나면 자동 차단)
```

## 다 채운 뒤 — 검사 돌리기

```bash
gates/check-bundle-complete.sh   bundle-manifest.yaml
gates/check-roles-and-waivers.sh bundle-manifest.yaml
```
