# da-review · DA 검토 자동화 하네스

## 용도 (무엇을 하는가)

프로젝트 착수 전, **DB 설계 산출물이 행내 데이터 표준을 지키는지 자동으로 검사**하는 하네스입니다.
DA(Data Architect) 검토에서 반복·기계적으로 점검하던 항목을 **결정적 규칙 엔진**으로 대신합니다.

- **검토 대상 2종**
  1. **DB설계서** — 테이블/컬럼 (명명규칙·도메인·인포타입·PK·관계·속성)
  2. **인스턴스코드 정의서** — 업무인스턴스명 + 코드값 (2시트)
- **결정적**(검사에 LLM 미사용) → 같은 입력 = 같은 결과. 재현·추적 가능.
- **통과 / 반송(사유 + 권고)** 을 고정 형식으로 산출.

> 검사 기준(메타)만 교체하면 타 프로젝트에 그대로 재사용 — 각 하네스는 **MSA처럼 독립**.

## 동작 흐름

```
자유양식 설계도(DDL·텍스트·엑셀)
        │  ① 변환 (에이전트가 INPUT 규격으로)
        ▼
   INPUT (yaml)  ──②──▶  게이트(결정적 검사)  ──③──▶  결과(통과 / 반송 + 사유·권고)
                          gates/*.sh                  고정 JSON 형식
```

- **검사(②③)는 룰베이스 게이트** — `meta/standard-meta.yaml`(표준)을 기준으로 판정.
- **변환(①)만 에이전트(Claude Code)** 가 수행 — 자유양식을 INPUT 규격으로 옮김.

---

## 빠른 시작

### 1) 받기 + 설치
```bash
# kit가 루트인 브랜치를 받습니다
git clone -b gitlab-export https://github.com/easyseop/Harness-work.git da-review
cd da-review
pip install pyyaml        # python3 + pyyaml 필요
```

### 2-A) 에이전트로 쓰기 (권장) — `/da-start`
Claude Code로 이 폴더를 열고 채팅창에:
```
/da-start
```
→ ① 자기소개 → ② **무엇을 검토할지 3지선다**(DB설계도 / 인스턴스코드 / 모두)
→ ③ `input/freeform/` 의 후보 파일 선택 → ④ 변환 → 게이트 → ⑤ 통과/반송 보고.

### 2-B) 게이트만 직접 돌리기 (CLI, 결정적)
```bash
# DB설계서 검토 (테이블명·컬럼·인포타입·PK·관계 / 속성명)
bash gates/check-physical.sh   input/review-target.good.yaml
bash gates/check-attribute.sh  input/review-target.good.yaml

# 인스턴스코드 정의서 검토 (2시트: 명명 + 코드값)
bash gates/check-instance-code.sh input/instance-code.good.yaml

# 결과를 고정 JSON 파일로 저장
DA_OUT=result.json bash gates/check-physical.sh input/review-target.bad.yaml
cat result.json

# input/ 의 모든 산출물 일괄 검사
bash run-all.sh
```
종료코드: **통과 0 / 반송 1**. 반송 시 `findings[]` 에 `사유(message) + 권고(suggestion)`.

### 3) 자가 검증
```bash
bash tests/run-golden.sh     # 예상결과(golden) vs 실제결과 비교 — 7/7 PASS
```
대량 검증도 통과: 자동 생성한 **DB설계서 100건 + 인스턴스코드 정의서 100건**
(유효 75 + 위반 25 각각)을 게이트에 돌려 **오반송 0 · 놓침 0 · 크래시 0**.

---

## 디렉터리 구성

```
da-review/  (= 하네스 루트)
├── CLAUDE.md                  # 에이전트 실행 대본(/da-start 가 따르는 흐름)
├── .claude/commands/da-start.md   # 슬래시 커맨드
├── meta/                      # ★표준(기준)
│   ├── standard-meta.yaml         # 규칙 — 도메인(90)·명명규칙·길이정책·인스턴스 규칙
│   ├── standard-words.yaml        # 표준단어 사전 9,258쌍 (한글→영문약어, 실데이터)
│   └── domains.generated.yaml     # 도메인 카탈로그 79종 (참고용)
├── gates/                     # ★검사 게이트(결정적)
│   ├── check-physical.sh          # DB설계: 테이블명·컬럼·인포타입·PK·관계
│   ├── check-attribute.sh         # DB설계: 속성명 + 컬럼↔속성 정합
│   └── check-instance-code.sh     # 인스턴스코드 정의서(2시트)
├── schemas/                   # 입력/출력 고정 스키마(JSON Schema)
├── intake/                    # 변환·사전점검(check-ready)·표준테이블 지정
├── input/
│   ├── freeform/                  # 자유양식 원본(DDL·텍스트·인스턴스) = 실제 I/O 시연
│   ├── mock-attributes.yaml       # 속성 목데이터 10,000 (검증·시연용, 중복 0)
│   └── *.yaml                     # 게이트 기본/골든 입력
├── tests/golden/ + run-golden.sh  # 골든 테스트
├── docs/검증시연/             # 검증기준·케이스 카탈로그·출처·디자인 자료
├── run-all.sh                 # input/ 일괄 검사
└── FORMATS.md                 # 입출력 형식 정의
```

## 검증 범위 (게이트 3개 · 검증 29개)

| 단계 | 게이트 | 검증 항목 |
|---|---|---|
| ① DB설계 | check-physical (19) + check-attribute (4) | 테이블명·컬럼 이름조합·인포타입·PK·관계·속성 = **23** |
| ② 인스턴스코드 | check-instance-code (11) | 명명(6) + 코드값(5) = **11** |

- 항목별 상세(정상/오류 예시·사유·출처)는 `docs/검증시연/검증기준_전체설명.md` 참고.

## 표준 데이터 (실데이터 반영)

행내 실제 표준 산출물에서 추출해 표준을 채웠습니다.

| 항목 | 규모 | 위치 |
|---|---|---|
| 표준단어 (한글→영문약어) | **9,258쌍** | `meta/standard-words.yaml` (게이트가 인라인과 병합 로드) |
| 도메인 | **90종** (실제 길이 반영) | `meta/standard-meta.yaml` |
| 속성 목데이터 | **10,000건** (중복 0) | `input/mock-attributes.yaml` |

핵심 동작 규칙:

- **인포타입 = 도메인 + 타입크기**. 숫자는 CHAR/DECIMAL의 크기(`년월일8`=CHAR(8), `금액18.3`=DECIMAL(18,3)).
- **인포타입이 도메인의 진실의 근원** — 컬럼 끝말을 추측하지 않고 인포타입에 적힌 도메인을 신뢰.
  덕분에 **중첩 도메인 공존**(`명50`=고객+명, `고객명6`=고객명 자체)을 그대로 수용.
- **길이 검증 정책**(`length_policy`): 기본 `format_only`(크기는 숫자/소수 형식만 검증),
  `strict_domains`(년월일·년월·여부·성별·시각)만 길이 목록을 강제. → 샘플 데이터의 불완전한
  길이목록 때문에 정상 크기를 오반송하지 않음.

## 표준값(메타) 교체 안내

- 단어·도메인은 실데이터 반영됨. 앱·소그룹 코드 등 일부는 아직 **대표 mock** 입니다.
- 실제 행내 등록목록으로 **메타(+`standard-words.yaml`)만 교체**하면 게이트·로직 수정 없이 동일 동작.
- 어디까지 문서근거이고 어디부터 보강 필요한지는 `docs/검증시연/기준_출처_구분.md` 참고.
- 영문변수명 규칙 = **camelCase**(첫글자 소문자, 예: 고객성별 → `custSex`).

## 원칙

- **입출력 형식만 사이트별로 교체** — 게이트 로직·META 규칙·스키마 구조는 불변.
- **판정은 게이트가, 에이전트는 묻고·변환하고·실행·정리**(CLAUDE.md).
