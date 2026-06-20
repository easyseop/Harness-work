# 채우기 설명서 (FILL-GUIDE) — secure-sdlc

조직의 보안 스캔 도구를 돌린 뒤, 그 결과를 `scan-report.json` 형식으로 옮깁니다.
실제 예시는 `scan-report.example.json`.

---

## scan-report.json — 구조

| 칸 | 뜻 |
|---|---|
| `project` | 프로젝트 식별값 |
| `scanned_on` | 스캔한 날짜 (YYYY-MM-DD) |
| `scans_run` | 실제로 돌린 스캔 목록 (예: `secret_scan`, `dependency_scan`) |
| `secret_findings` | 발견된 비밀값의 **위치만** (값은 X) |
| `vulnerabilities` | 발견된 취약점 목록 |

## secret_findings — 비밀값 발견 (위치만)

```json
{ "file": "src/config.py", "line": 12, "rule": "hardcoded-token" }
```
값 자체는 절대 적지 않습니다. 깨끗하면 빈 목록 `[]`.

## vulnerabilities — 취약점

```json
{ "id": "CVE-2025-22222", "component": "yaml-parser 1.0.0",
  "severity": "medium", "fixed_in": "1.0.1" }
```
- `severity`: `none|low|medium|high|critical` 중 하나
- `fixed_in`: 고쳐진 버전 (있으면)

## 기준은 어디서 정하나

`policy.yaml` 의 `vulnerability.max_allowed_severity`(기본 medium)와
`secret_scan.block_if_any`(비밀값 0건 강제)에서 정합니다. 보안팀 소유라 프로젝트가 임의로 못 낮춥니다.

## 다 정리한 뒤 — 검사 돌리기

```bash
gates/check-secret-scan.sh    scan-report.json
gates/check-vuln-threshold.sh scan-report.json
```
