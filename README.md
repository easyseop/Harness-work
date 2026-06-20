# 은행 반입 하네스 프레임워크

외부망에서 개발한 것을, 코드를 거의 고치지 않고 내부망(행내)으로 안전하게 들여보내기 위한
도구 모음입니다. 각 단계에서 "지켜야 할 규칙"을 **개발하는 순간에** 자동으로 강제합니다.

> 처음이라면 `core/GLOSSARY.md`(용어풀이) → 이 문서 → 관심 있는 하네스의 `MANUAL.md` 순서로 읽으세요.

---

## 한 장 그림

```
                          [ Spine — 얇은 몸통 ]
            발견 · 의존성 정렬 · 단계 진행 · 결과 수집  (판단은 안 함)
                                 │
   ┌──────────┬──────────┬──────┴───────┬───────────┬─────────────┐
classify     build      verify         import     reproduce        (5단계)
   │          │          │              │            │
   └── 각 단계에 하네스들이 manifest 로 "끼어들어" 게이트로 검사 ──┘
                                 │
                          [ 반입 묶음 ]  ← 모든 증거가 한곳으로 수렴
```

설계 원칙: **Spine은 모른다. 하네스가 선언한다. Spine은 manifest대로 부르고 모은다.**

---

## 폴더 구성

| 폴더 | 내용 |
|---|---|
| `00-spine-and-manifest-spec.md` | **키스톤 규격** — Spine·Manifest 표준 |
| `core/` | 공통 규칙: `AGENTS.md`(권위 규칙), `CLAUDE.md`(얇은 포인터), `GLOSSARY.md`(용어), `ARCHITECTURE_INVARIANTS.md`(불변식) |
| `spine/` | 중앙 오케스트레이터 (`spine.py`) + 데모 |
| `*-kit/` | 하네스 10개 (각자 manifest·policy·게이트·예시·매뉴얼) |
| `harness-manifest.template.yaml` | 새 하네스용 manifest 양식 |

---

## 하네스 10개

| 단계 | 하네스 | 하는 일 (한 줄) |
|---|---|---|
| classify | **policy-profile** | 분류·허용 스택 고정 (제일 먼저) |
| classify/verify | **oss-runtime-eol** | 오픈소스 라이선스·수명(EOL) 검사 |
| build/verify | **internal-solution** | 내부 시스템 연동을 계약·대역으로만 (메신저 등) |
| build/verify | **data-standard** | 데이터 이름·메타데이터·흐름 표준 |
| build/verify | **config-secret** | 실제 값을 빈 자리로, 내부망에서 주입 |
| build/verify | **secure-sdlc** | 비밀값·취약점 스캔 |
| build/verify | **contract-test** | 코드가 계약을 지키는지 검증 |
| build/verify/reproduce | **build-provenance** | 빌드 출처·재현성 |
| import | **import-gate** | 반입 묶음 완성·역할분리·예외만료 (마지막 관문) |
| reproduce | **deploy-runbook** | 배포 안내서(롤백 포함) |

각 하네스 폴더의 `MANUAL.md` 에 "왜 있나 · 안 쓰면 · 실제예시 · 내 일 vs 자동 · FAQ" 가 있습니다.

---

## 빠르게 돌려보기

```bash
pip install pyyaml          # 1회 (내부망이면 담당자 문의)
cd spine
python3 spine.py plan       # 단계별 실행 순서
python3 spine.py run --demo # 메신저 사례로 전체 게이트 실행 (게이트 19개 통과)
```

---

## 색깔 표시 규칙 (각 키트 공통)

- 🟢 제가 완성한 부분 (구조·게이트·예시·스키마)
- 🟡 당신/담당자가 채우는 부분 (policy.yaml 등 조직 정책)
- 🔴 절대 외부망에 두면 안 되는 것 (실제 주소·접속코드·개인정보)

---

## 핵심 안전 규칙 (불변식 요약)

- 실제 endpoint·secret·개인정보는 어떤 파일에도 넣지 않는다 (내부망 주입).
- 게이트 우회는 `--no-verify` 가 아니라 **만료 있는 waiver** 로만.
- 만든 사람이 혼자 반입·배포를 통과시킬 수 없다 (역할 분리).

자세한 내용: `core/ARCHITECTURE_INVARIANTS.md`
