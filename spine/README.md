# Spine — 중앙 오케스트레이터 (얇은 몸통)

> 규격: `../00-spine-and-manifest-spec.md` · 불변식: `../core/ARCHITECTURE_INVARIANTS.md`

## Spine이 하는 일 / 안 하는 일

**하는 일** (조율만):
1. `manifest.yaml` 이 있는 폴더를 하네스로 **발견**
2. `requires` 의존성으로 **위상정렬** (순환=설계오류)
3. 단계(classify→build→verify→import→reproduce)별로 hooks 된 하네스를 **순서대로 호출**
4. 각 하네스의 게이트를 실행하고 **표준 결과(JSON)를 수집**
5. blocking 게이트 실패 시 그 단계 종료 후 **진행 중단** (명세 §3.3)

**안 하는 일** (INV-1):
- 라이선스/명명/취약점 같은 **업무·정책 판단을 하지 않음** → 전부 하네스 안에 있음
- 특정 AI 도구에 종속되지 않음
- 실제 endpoint·secret 을 알지 못함

> 기능 추가 = **새 하네스 폴더 추가**. Spine 코드는 안 고침.

## 사용법

```bash
# 오케스트레이터
python3 spine.py discover            # 등록된 하네스 목록
python3 spine.py plan                # 단계별 실행 순서(위상정렬)
python3 spine.py run --demo          # 예시 입력으로 전체 게이트 실행
python3 spine.py run --only=<id> --demo   # 내 하네스 + 의존 윗단만 실행
python3 spine.py bundle --demo       # 실행 → 증거 수집 → 번들 자동 조립 → 반입 게이트 검사

# 담당자 도구
python3 harness-test.py <id>         # 자가진단: 좋은건 통과·나쁜건 차단 확인
python3 verify-harness.py <id>       # 베이스 검증기: 규격 적합성 검수
python3 verify-harness.py --all      # 전체 하네스 규격 검수
```

## 파일

| 파일 | 설명 |
|---|---|
| `spine.py` | 얇은 오케스트레이터 (발견·정렬·실행·수집, `--only` 지원) |
| `verify-harness.py` | **베이스 검증기** — 매니페스트 검증 + 규격 적합성 (형식·안전) |
| `harness-test.py` | 하네스 자가진단 — 좋은/나쁜 예시로 게이트 양방향 검증 |
| `demo-inputs.yaml` | 데모 실행용 입력 매핑 (테스트 픽스처, 업무 로직 아님) |
| `demo-evidence.yaml` | 번들 조립용 하네스별 아티팩트 매핑 (테스트 픽스처) |
| `demo-workspace/` | 데모용 깨끗한 코드 샘플 |
| `bundle-out/` | `bundle` 실행 시 자동 생성되는 번들 (증거 + bundle-manifest) |
| `last-run.json` | 마지막 실행의 표준 결과 (자동 생성) |

## 베이스 검증기가 보는 것 / 안 보는 것

- ✅ **자동(형식·안전):** 매니페스트 필수항목·형식, 규격 버전, hooks 단계명,
  requires 실재·순환, 게이트 runner 존재, 실제 비밀값 없음, 빈칸(미정/TBD) 없음, 자가진단 통과
- ❌ **사람 몫(업무·의미):** 규칙이 조직 정책에 맞는지, 게이트 로직이 업무적으로 옳은지
  → 동료 리뷰가 본다

## 데모 실행 결과 (참고)

`run --demo` 는 메신저 사례로 5단계 10개 하네스를 끝까지 돌려 게이트 19개가
모두 통과하는 것을 보여줍니다. (policy-profile 은 채워진 `policy.example.yaml` 사용)

## 요구 사항

python3 + pyyaml (`pip install pyyaml`). 내부망이면 담당자에게 문의.
