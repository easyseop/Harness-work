# 채우기 설명서 (FILL-GUIDE) — build-provenance

`provenance.template.yaml` 에 빌드 출처를 적습니다.
대부분의 값(해시·잠금파일·SBOM)은 빌드 도구가 만들어 주니, 그걸 옮기면 됩니다.
실제 예시는 `provenance.messenger.example.yaml`.

---

## provenance — 필수 항목

| 칸 | 뜻 | 예시 |
|---|---|---|
| `project` | 프로젝트 식별값 | `PRJ-2026-014` |
| `source_ref` | 어떤 소스로 빌드 | `v1.0.0` 또는 커밋해시 |
| `built_by` | 누가/무엇이 빌드 | `CI-빌드시스템` |
| `built_on` | 빌드 시각 | `2026-06-16T10:00:00Z` |
| `inputs_hash` | 입력(소스+잠금) 지문 | `sha256:...` |
| `output_hash` | 결과물 지문 | `sha256:...` |

## artifacts — 잠금/구성요소

```yaml
artifacts:
  lockfile: poetry.lock      # 의존성 잠금 파일
  sbom: sbom.spdx.json       # 구성요소 목록
```

## reproduce — 내부망 재빌드 (나중에)

```yaml
reproduce:
  rebuilt_output_hash: sha256:...   # 내부망에서 재빌드한 결과 해시
```
이 값이 `output_hash` 와 같아야 재현성 통과. 아직 없으면 비워 두면 됩니다(보류).

## 다 적은 뒤 — 검사 돌리기

```bash
gates/check-provenance-complete.sh provenance.yaml
gates/check-reproducible.sh        provenance.yaml
```
