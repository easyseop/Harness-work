# intake — DA검토 앞단 (게이트 실행 전 준비)

검사(게이트)는 **결정적으로 불변**. 앞단에만 준비 작업을 둔다.

## 순서 (중요)

```
0. (설계도 받기 전) 표준 테이블 목록 확정 ── 사람이 지정
      → intake/standard-tables.yaml  (여기 적힌 것만 표준 = DA검토 대상)

1. 표준 테이블 원본 설계도 수집 (형태 다양)

2. 변환 → 정형 INPUT(yaml)   ── 형태에 따라 둘 중 하나
      (A) 고정양식(엑셀/CSV)  → convert-csv.py     (LLM 불필요, 결정적)
      (B) 자유/비정형         → convert-llm.py     (내부 LLM 필요, 출력은 스키마 검증)

3. 사전점검  → check-ready.sh   (표준여부·정보 충분성)

4. 게이트(결정적 검사)  → gates/check-*.sh → OUTPUT
```

- **표준여부**는 0번에서 **사람이 정함**(설계도와 무관). 변환 시 standard 플래그로 입혀짐. 비표준은 검토 제외.
- **LLM은 2-(B) 변환에만**. 검사·표준판정엔 안 씀.

## 파일

| 파일 | 역할 | LLM |
|---|---|---|
| `standard-tables.yaml` | 사람이 지정하는 표준 테이블 목록 | — |
| `convert-csv.py` | 고정 CSV → INPUT (표준목록 반영) | ❌ 불필요 |
| `convert-llm.py` | 자유형식 → INPUT (call_llm 자리 = 사내 API) | ✅ 필요(hook) |
| `check-ready.sh` | 표준여부 + 정보 충분성 점검 | ❌ |
| `sample-design.csv` | CSV 양식 예시 | — |

## 사용 예 (고정 CSV 경로, 끝까지 결정적)

```bash
# 변환 (표준목록 적용)
python3 intake/convert-csv.py intake/sample-design.csv intake/standard-tables.yaml > /tmp/in.yaml
# 사전점검
bash intake/check-ready.sh /tmp/in.yaml
# 게이트
bash gates/check-physical.sh /tmp/in.yaml
```

## 자유형식(LLM) 경로

`convert-llm.py` 의 `call_llm()` 을 **사내 내부망 LLM API** 로 교체.
- LLM은 변환만, 없는 값은 빈칸(추측 금지), standard 판단 금지.
- 출력은 `validate()` 로 스키마 핵심 검증 → 통과해야 다음 단계로 (환각 방지).
- 보안: 설계도는 내부정보 → **내부망 LLM** 사용.
