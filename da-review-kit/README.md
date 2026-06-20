# da-review · DA 검토 하네스

프로젝트 착수 전, **DB설계서**와 **인스턴스코드 정의서**가 행내 데이터 표준을 지키는지
자동 검사한다. (이름조합·명명규칙·인포타입·속성/컬럼 정합·인스턴스코드 규칙)

## 구성

```
da-review-kit/
├── meta/standard-meta.yaml   # 표준(기준) — 도메인·표준단어·명명규칙
├── gates/                    # 검사 게이트
│   ├── check-physical.sh         # DB설계서: 테이블명·컬럼명·인포타입·PK·관계
│   ├── check-attribute.sh        # DB설계서: 속성명 표준 + 컬럼↔속성 정합
│   └── check-instance-code.sh    # 인스턴스코드 정의서(2시트)
├── input/                    # 입력 예시
├── schemas/                  # 입력/출력 고정 스키마(JSON Schema)
├── tests/golden/             # 골든 테스트 데이터 + 예상결과
└── tests/run-golden.sh       # 예상 vs 실제 비교
```

## 설치 — da-review만 받기

> ⚠️ 작업 브랜치는 `claude/laughing-hamilton-tfzkqw` 입니다 (main 아님).

**방법 A — 전체 클론 후 폴더만 사용**
```bash
git clone -b claude/laughing-hamilton-tfzkqw https://github.com/easyseop/Harness-work.git
cd test_me-/da-review-kit
```

**방법 B — da-review-kit 만 받기 (sparse checkout)**
```bash
git clone --no-checkout -b claude/laughing-hamilton-tfzkqw https://github.com/easyseop/Harness-work.git
cd test_me-
git sparse-checkout init --cone
git sparse-checkout set da-review-kit
git checkout
cd da-review-kit
```

**의존성**
```bash
pip install pyyaml          # python3 + pyyaml 필요
```

## 사용

```bash
# 1) 사람용 텍스트 결과 + exit code (통과 0 / 반송 1)
bash gates/check-physical.sh      input/db-design.example.yaml
bash gates/check-instance-code.sh input/instance-code.good.yaml

# 2) 고정 형식 JSON 결과 파일 생성 (DA_OUT 지정)
DA_OUT=result.json bash gates/check-physical.sh tests/golden/db-bad.input.yaml
cat result.json

# 3) 골든 테스트 (예상결과와 실제결과 비교)
bash tests/run-golden.sh
```

## 입출력 형식

- 형식 정의는 `FORMATS.md` 참고. **입출력 형식만 사이트별로 바꾸고**
  게이트 로직·META 규칙·스키마 구조는 바꾸지 않는다.
- 표준값(도메인·표준단어·앱코드 등)은 현재 **대표 mock** — 실제 행내 등록목록으로
  `meta/standard-meta.yaml` 만 교체하면 된다.
