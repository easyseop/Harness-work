# Spine & Harness Manifest 규격 (v0.1)

작성일: 2026-06-17
상태: draft (키스톤 문서 — 다른 모든 하네스가 이 규격을 따른다)

> 이 문서는 은행 반입 하네스의 **표준 인터페이스**를 정의한다.
> 여기서 못 박은 규격이 없으면 개별 하네스들이 제각각 만들어져 통합이 불가능해진다.
> 따라서 이 문서는 어떤 capability 하네스보다 **먼저** 확정되어야 한다.

---

## 0. 한 장 요약

```text
Spine(전체를 조율하는 중심부) : 작업 순서 진행 + 하네스 부르기 + 결과 모으기만 담당. 판단 규칙은 갖지 않음.
Capability 하네스(모듈) : 실제 기능. 각자 manifest로 "어느 단계에 끼는지/무엇을 검사/무엇을 증적으로 내는지" 선언.
Manifest(표준 계약)     : 모든 하네스가 동일한 형식으로 자기 자신을 기술. Spine은 manifest만 보고 하네스를 다룬다.
반입 묶음(수렴점)        : 모든 하네스의 증적이 한곳으로 모인다.
```

설계 원칙 한 줄: **Spine은 모른다. 하네스가 선언한다. Spine은 manifest대로 부르고 모은다.**

---

## 1. 두 계층 모델

### 1.1 Spine — 전체를 조율하는 중심부

Spine이 **하는 일**:

- 입력(정규화된 기술 요건서)을 받아 실행할 워크플로우 단계를 진행한다.
- 각 단계(`classify`/`build`/`verify`/`import`/`reproduce`)에서, 그 단계에 `hooks` 선언된 하네스들을 **순서대로 호출**한다.
- 하네스가 돌려준 결과(증적·게이트 통과여부·waiver)를 **반입 묶음으로 수렴**한다.
- 하네스 간 `requires` 의존성을 보고 **실행 순서를 위상정렬**한다.
- 어떤 하네스가 실패(blocking gate fail)하면 다음 단계 진행을 중단한다.

Spine이 **하지 않는 일** (중요):

- 라이선스 차단 기준, PII 패턴, 명명 규칙 같은 **업무/정책 로직을 갖지 않는다.** 그건 전부 하네스 안에 있다.
- 특정 AI 도구(Claude/Codex/Cursor)에 종속되지 않는다. 도구별 지시문은 생성물(adapter)로 취급한다.
- 내부 endpoint/secret을 알지 못한다.

> 결과적으로 Spine 코드는 작고 거의 변하지 않는다. 기능 추가 = 새 하네스 등록이지 Spine 수정이 아니다.

### 1.2 Capability 하네스 — 독립 모듈

각 하네스는 다음을 **스스로 소유**한다.

- `manifest.yaml` : 자기 기술서 (이 규격의 §2)
- `policy.yaml` : 자기 정책 (예: 차단 라이선스 목록) — 통짜 `harness.yaml` 대신 분산
- `gates/` : 자기 검사 스크립트
- `templates/`, `checklists/` : 자기 산출물 양식
- `evidence-spec` : 반입 묶음에 무엇을 기여하는지

하네스는 **다른 하네스의 내부를 직접 호출하지 않는다.** 필요하면 `requires`로 의존성만 선언하고, 산출물(증적/계약)을 통해 간접적으로 연결된다.

---

## 2. 표준 Harness Manifest 규격

모든 하네스는 루트에 `manifest.yaml`을 둔다. Spine은 **이 파일만 보고** 하네스를 다룬다.

```yaml
# ---- 식별 ----
manifestVersion: "0.1"        # 이 규격의 버전. Spine 호환성 판단 기준.
id: data-standard             # 하네스 고유 id (소문자-하이픈)
version: "1.0.0"              # 하네스 자체 버전 (semver)
title: "메타데이터 · 데이터 표준 하네스"
owner: data-governance-team   # 소유 조직/역할
status: draft                 # draft | active | deprecated

# ---- 어느 단계에 끼어드는가 (가로지름 표현) ----
hooks:                        # Spine의 워크플로우 단계 중 참여 지점
  - seed                      # 명명규칙·데이터등급 고정
  - build                     # 스키마 계약 설계
  - verify                    # 표준 위반 게이트

# ---- 의존성 ----
requires:                     # 먼저 실행되어야 하는 다른 하네스 id
  - policy-profile
optional:                     # 있으면 연동, 없어도 동작
  - traceability

# ---- 입력 ----
inputs:
  - name: requirements
    from: spine                # spine | harness:<id> | bundle
    required: true
  - name: classification
    from: harness:policy-profile
    required: true

# ---- 정책 (분산 정책 파일) ----
policy:
  file: policy.yaml
  overridable: true            # 프로젝트가 override 가능한지

# ---- 게이트 (검사) ----
gates:
  - id: check-naming
    phase: verify
    blocking: true             # true=실패 시 진행 중단, false=경고
    waiverable: true           # waiver로 우회 가능 여부
    runner: gates/check-naming.sh
  - id: check-lineage
    phase: verify
    blocking: false
    waiverable: true
    runner: gates/check-lineage.sh

# ---- 증적 (반입 묶음에 기여하는 산출물) ----
evidence:
  - id: data-contract
    path: data-contract.json
    schema: schemas/data-contract.schema.json
    requiredForImport: true    # 반입 게이트에서 필수로 볼지

# ---- 추적성 훅 ----
traceability:
  emits: [requirement, design, code, evidence]  # 어떤 추적 레코드를 남기는지

# ---- 적용 조건 (선택) ----
appliesWhen:                   # 이 조건일 때만 Spine이 호출. 생략 시 항상.
  - field: 구현_대상_정보.업무_유형
    in: [API_서비스, 배치, 데이터플랫폼]
```

### 2.1 필수 필드

`manifestVersion`, `id`, `version`, `hooks` 는 필수. 나머지는 하네스 성격에 따라 생략 가능.

### 2.2 금지

- manifest에 실제 endpoint/secret/고객정보를 절대 넣지 않는다.
- `TBD`는 template/placeholder에서만 허용. 실제 하네스 manifest에는 남기지 않는다.

---

## 3. Spine 실행 계약

Spine이 하네스를 호출하고 결과를 받는 **표준 프로토콜**.

### 3.1 호출

Spine은 각 단계에서 다음을 수행한다.

```text
1. 현재 단계(phase)에 hooks된 하네스를 모은다.
2. requires 의존성으로 위상정렬한다. (순환 의존 = 설계 오류)
3. appliesWhen 조건을 평가해 적용 대상만 남긴다.
4. 순서대로 각 하네스의 entrypoint를 호출한다.
```

### 3.2 하네스가 돌려주는 결과 (표준 출력)

각 하네스는 실행 후 표준 결과 객체를 반환한다.

```json
{
  "harness": "data-standard",
  "version": "1.0.0",
  "phase": "verify",
  "status": "passed",
  "gates": [
    { "id": "check-naming",  "result": "passed" },
    { "id": "check-lineage", "result": "warning", "message": "..." }
  ],
  "evidence": [
    { "id": "data-contract", "path": "evidence/data-standard/data-contract.json" }
  ],
  "waivers": [],
  "trace": [
    { "type": "evidence", "ref": "...", "links": ["REQ-012", "DES-003"] }
  ]
}
```

`status` 값: `passed` | `warning` | `failed` | `skipped`.

### 3.3 차단 규칙

- `blocking: true` 게이트가 `failed`면 Spine은 해당 단계 종료 후 진행을 멈춘다.
- 단, 유효한 waiver가 있으면 통과로 처리하되 **반입 묶음에 waiver 기록을 남긴다.**

---

## 4. 정책 합성 (DEC-004 개정)

기존 단일 `harness.yaml` 대신, **하네스별 policy.yaml을 합성한 profile**을 사용한다.

```text
하네스별 policy.yaml  ──┐
                       ├─►  profile 합성  ──►  유효 정책(effective policy)
프로젝트 override     ──┘
```

- 충돌 우선순위: `프로젝트 override` > `profile` > `하네스 기본 policy.yaml`.
- 이렇게 하면 하네스가 늘어도 정책이 한 파일에 몰리지 않고, 모듈과 함께 버전 관리된다.

---

## 5. 등록과 발견

- Spine은 정해진 경로를 스캔해 `manifest.yaml`이 있는 디렉토리를 하네스로 인식한다.
- `manifestVersion`이 Spine이 지원하는 범위를 벗어나면 **로드 거부**하고 명확히 에러를 낸다.
- 등록은 "파일 추가"만으로 끝난다. Spine 코드 수정 불필요.

---

## 6. 워크플로우 단계 (행내 검증 프로세스에 정렬)

Spine의 기본 단계는 **5개**다. 이 단계들은 새로 만든 개념이 아니라, 이미 정의된 **4개 게이트 묶음**(`local-fast`/`external-ci-required`/`import-required`/`internal-rebuild`)에 정렬시킨 것이다. 각 단계는 해당 게이트로 닫힌다.

| # | Spine 단계 | 역할 | 닫는 게이트 | 망 / 주체 |
|---|---|---|---|---|
| ① | `classify` | 구현 전 분류·제약 고정 (무엇/지킬것/안할것) | check-classification-complete | 외부망 / 하네스 |
| ② | `build` | 분류에 맞게 코드·계약·대역·검사기록 만들기 | local-fast | 외부망 / 개발자 |
| ③ | `verify` | 외부망에서 가능한 모든 검증 완료 | external-ci-required | 외부망 / 검증역할 |
| ④ | `import` | 반입 묶음 봉인 + 경계 최종심사 + 승인 (air-gap 전환) | import-required | **반입 경계 / 승인역할** |
| ⑤ | `reproduce` | 내부 재현빌드 + 실어댑터·secret 주입 + smoke + 변경관리 승인 | internal-rebuild | **내부망(행내) / 행내** |

원칙:

- ①②③은 외부망에서 하네스가 주도해 "내부로 들여보낼 수 있는 묶음"을 만든다.
- ④는 가장 강하게 통제되는 1급 전환이다. 개발자가 스스로 통과시킬 수 없고 별도 승인역할이 닫는다(역할 분리).
- ⑤는 행내가 재개발이 아니라 재현·확인·승인만 한다. 하네스는 실행 주체가 아니라 산출물·절차를 제공한다.

> 기존 우로보로스 6단계(`seed/trd/decompose/run/evaluate/evolve`)는 **선택적 상세 워크플로우**로 강등한다. 원하는 팀은 `build` 한 단계를 trd/decompose/run으로 더 잘게 운영해도 된다. Spine은 강제하지 않는다.

---

## 7. 버전·호환성

- `manifestVersion` : 규격 버전. Spine은 지원 범위를 명시.
- 하네스 `version` : semver. breaking change는 major 증가.
- 하네스가 의존(`requires`)하는 대상의 버전 범위를 선언할 수 있게 후속 버전에서 확장 예정.

---

## 8. 이 규격이 강제하는 불변식 (ARCHITECTURE_INVARIANTS 후보)

- INV-1: Spine은 정책/업무 로직을 갖지 않는다.
- INV-2: 모든 하네스는 manifest.yaml로만 Spine과 소통한다.
- INV-3: 하네스는 다른 하네스 내부를 직접 호출하지 않는다 (requires + 산출물로만 연결).
- INV-4: 모든 증적은 반입 묶음으로 수렴한다.
- INV-5: manifest·정책·증적에 실 endpoint/secret/고객정보를 넣지 않는다.
- INV-6: 게이트 우회는 `--no-verify`가 아니라 만료 있는 waiver로만.

---

## 9. 다음 문서

이 규격이 확정되면 다음을 만든다.

1. `harness-manifest.template.yaml` (동봉)
2. `examples/policy-profile.manifest.yaml` (동봉)
3. `AGENTS.md` (실질 규칙, 이 규격 참조)
4. `CLAUDE.md` (AGENTS.md를 가리키는 얇은 포인터)
5. `ARCHITECTURE_INVARIANTS.md` (§8을 정식 문서로)
