# oss-runtime-eol 채우기 키트

하네스 **oss-runtime-eol**(오픈소스·수명 관리)를 완성하기 위한 키트입니다.
처음이면 `MANUAL.md` 부터 읽으세요. 용어는 `core/GLOSSARY.md`.

## 이 하네스가 하는 일 (한 줄)

> 쓰는 오픈소스의 라이선스가 허용 범위인지, 런타임/라이브러리가 수명종료(EOL)
> 되었거나 임박했는지 검사한다.

## 폴더 안에 뭐가 있나

| 파일 | 누가 | 설명 |
|---|---|---|
| `MANUAL.md` | (읽기) | **처음 보는 사람용 매뉴얼** |
| `policy.yaml` | 🟡 거버넌스팀 | 허용/금지 라이선스, 런타임 EOL 날짜표 |
| `components.template.yaml` | 🟡 개발자 | 구성요소 목록 양식 |
| `components.messenger.example.yaml` | 🟢 예시 | 메신저 모듈 구성요소 샘플 |
| `gates/check-license.sh` | 🟢 | 라이선스 허용/금지 검사 |
| `gates/check-eol.sh` | 🟢 | 런타임 수명종료 검사 |
| `manifest.yaml` | 🟢 | 하네스 자기소개 파일 |
| `FILL-GUIDE.md` | (읽기) | 목록 작성 설명서 |
| `SAFE-OR-NOT.md` | 🔴 (읽기) | 안전수칙 |

## 빠른 시작

```bash
gates/check-license.sh components.messenger.example.yaml
gates/check-eol.sh     components.messenger.example.yaml policy.yaml 2026-06-16
```
