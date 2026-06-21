# 변환 가이드 — 설계도 → DA검토 INPUT

설계도(엑셀/ERD/자유형식)를 `schemas/db-design.schema.json`(또는 instance-code) 형식으로 옮기는 **매핑 규칙**.
에이전트(자유형식)·`convert-csv.py`(고정형식) 모두 이 규칙을 따른다.

## 공통 규칙
- **있는 값만** 옮긴다. **없는 값은 추측·창작 금지** → 빈 문자열(`""`)로 두고, 사전점검에서 사용자에게 묻는다.
- **standard(표준여부)는 변환 단계에서 판단하지 않는다.** → `intake/standard-tables.yaml`(사람 지정)로 따로 입힌다.
- **인포타입은 "도메인+길이" 표기**로 통일한다. (예: `년월일8`, `금액18.3`, `구분코드1`) — `CHAR(8)` 같은 DBMS 타입은 `typelength`로 따로.

## DB설계서 매핑 (설계도 흔한 항목 → INPUT 필드)

| 설계도의 항목(예시 명칭) | → INPUT 필드 | 비고 |
|---|---|---|
| 테이블 물리명 / 영문테이블명 | `tables[].physical_name` | 예: TSDPSAA01 |
| 테이블 한글명 / 설명 | `tables[].logical_name` | 선택 |
| 주제영역 | `tables[].subject_area` | 선택 |
| 컬럼 한글명 / 논리명 | `columns[].korean` | 필수 |
| 컬럼 영문명 / 물리컬럼명 | `columns[].english` | 필수 |
| 속성명 | `columns[].attribute` | 컬럼명과 다를 때만, 없으면 생략 |
| 도메인+길이 / 인포타입 | `columns[].infotype` | 필수, "도메인+길이" 표기 |
| 데이터타입 (CHAR(8) 등) | `columns[].typelength` | 선택 |
| 기본키 / PK / 키 여부 | `columns[].pk` | Y/PK/기본키 → `true` |
| NULL 허용 / Nullable | `columns[].nullable` | 허용 → `true` |
| 관계 / 카디널리티 (1:M, M:N) | `tables[].relationships[]` | `{type: "1:M", to: "상대테이블"}` |

## 인스턴스코드 정의서 매핑

| 설계도 항목 | → INPUT 필드 |
|---|---|
| (시트1) 어플리케이션코드/명, 업무인스턴스명, 정의, 코드길이, 단말배포/외부데이터/목록테이블 여부 | `instance_names[].{app_code,app_name,instance_name,definition,code_length,terminal_deploy,external_data,list_table_managed}` |
| (시트2) 업무인스턴스명, 업무인스턴스코드, 업무인스턴스내용 | `code_values[].{instance_name,code,content}` |

## 변환 후
1. `intake/check-ready.sh` 또는 게이트로 **부족 정보 점검** → `category=missing` 항목은 사용자에게 질문해 보완.
2. 보완되면 `gates/check-*.sh` 실행.

## 예시 (자유형식 → INPUT)
```
설계도: "예금잔액 테이블 TSDPSAA01. 컬럼: 기준년월일(BASE_YMD, 년월일8, PK),
        계좌번호(ACCT_NO, 번호, PK), 예금잔액금액(DPST_BAL_AMT, 금액18.3)"
```
→
```yaml
tables:
  - physical_name: TSDPSAA01
    columns:
      - { korean: 기준년월일, english: BASE_YMD, infotype: "년월일8", pk: true,  nullable: false }
      - { korean: 계좌번호,   english: ACCT_NO,  infotype: "번호",    pk: true,  nullable: false }
      - { korean: 예금잔액금액, english: DPST_BAL_AMT, infotype: "금액18.3", pk: false, nullable: false }
```
