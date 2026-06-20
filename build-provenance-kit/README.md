# build-provenance 채우기 키트

하네스 **build-provenance**(빌드 출처·재현성)를 완성하기 위한 키트입니다.
처음이면 `MANUAL.md` 부터 읽으세요. 용어는 `core/GLOSSARY.md`.

## 이 하네스가 하는 일 (한 줄)

> 빌드 결과물이 어떤 입력으로·누가·언제 만들어졌는지 출처를 남기고, 잠금파일·SBOM 이
> 갖춰졌는지, 같은 입력이면 같은 결과가 나오는지(재현성) 검사한다.

## 폴더 안에 뭐가 있나

| 파일 | 누가 | 설명 |
|---|---|---|
| `MANUAL.md` | (읽기) | **처음 보는 사람용 매뉴얼** |
| `policy.yaml` | (거버넌스/플랫폼) | 출처 필수항목·잠금·SBOM·재현성 요구 |
| `provenance.template.yaml` | 🟡 빌드 담당 | 빌드 출처 양식 |
| `provenance.messenger.example.yaml` | 🟢 예시 | 메신저 모듈 빌드 출처 샘플 |
| `gates/check-provenance-complete.sh` | 🟢 ★ | 출처·잠금·SBOM 완결성 검사 |
| `gates/check-reproducible.sh` | 🟢 | 재빌드 결과 일치 검사 |
| `manifest.yaml` | 🟢 | 하네스 자기소개 파일 |
| `FILL-GUIDE.md` | (읽기) | 출처 작성 설명서 |
| `SAFE-OR-NOT.md` | 🔴 (읽기) | 안전수칙 |

## 빠른 시작

```bash
gates/check-provenance-complete.sh provenance.messenger.example.yaml
gates/check-reproducible.sh        provenance.messenger.example.yaml
```
