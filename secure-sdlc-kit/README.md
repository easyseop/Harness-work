# secure-sdlc 채우기 키트

하네스 **secure-sdlc**(안전한 개발 절차)를 완성하기 위한 키트입니다.
처음이면 `MANUAL.md` 부터 읽으세요. 용어는 `core/GLOSSARY.md`.

## 이 하네스가 하는 일 (한 줄)

> 개발 중 코드에 비밀값이 새지 않는지, 의존성에 알려진 취약점이 없는지 스캔하고,
> 정해진 심각도 기준을 넘으면 막는다.

## 폴더 안에 뭐가 있나

| 파일 | 누가 | 설명 |
|---|---|---|
| `MANUAL.md` | (읽기) | **처음 보는 사람용 매뉴얼** |
| `policy.yaml` | 🟡 보안팀 | 허용 심각도·필수 스캔 기준 |
| `scan-report.template.json` | 🟡 개발자 | 스캔 결과 정리 양식 |
| `scan-report.example.json` | 🟢 예시 | 메신저 모듈 스캔 결과 샘플 |
| `gates/check-secret-scan.sh` | 🟢 ★ | 비밀값 발견 시 차단 |
| `gates/check-vuln-threshold.sh` | 🟢 | 취약점 심각도 기준 검사 |
| `manifest.yaml` | 🟢 | 하네스 자기소개 파일 |
| `FILL-GUIDE.md` | (읽기) | 결과 정리 설명서 |
| `SAFE-OR-NOT.md` | 🔴 (읽기) | 안전수칙 |

## 빠른 시작

```bash
gates/check-secret-scan.sh    scan-report.example.json
gates/check-vuln-threshold.sh scan-report.example.json
```
