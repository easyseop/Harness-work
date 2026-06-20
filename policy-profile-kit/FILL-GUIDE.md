# 채우기 설명서 (FILL-GUIDE)

`policy.yaml` 의 빈칸(`TBD`)을 채우는 방법입니다. 개발 지식 없이도 채울 수 있게 풀어 썼습니다.

> 먼저 `SAFE-OR-NOT.md` 를 읽어 "적으면 안 되는 것"을 확인하세요.

---

## 1. allowed_tech_stack — "우리가 써도 되는 것"

이건 **"우리 조직/팀이 개발에 허용하는 도구"** 목록입니다. 모르면 팀에서 실제로 쓰는 걸 적으면 됩니다.

| 칸 | 무슨 뜻 | 어떻게 채우나 |
|---|---|---|
| `languages` | 프로그래밍 언어 + 버전 | 팀이 쓰는 언어. 예: `java-21`, `python-3.11` |
| `frameworks` | 큰 개발 틀 | 예: `spring-boot-3`. 행내 코어뱅킹 틀이면 `n-framework` 등. 안 쓰면 `없음` |
| `deploy_units` | 결과물 형태 | 자바면 보통 `jar` 또는 `war`. 컨테이너면 `컨테이너` |
| `deploy_targets` | 어디서 도나 | `온프레미스`(자체서버) / `kubernetes` / `레거시-WAS` / `배치-스케줄러` 중 |

💡 **잘 모르면**: 지금 운영 중인 비슷한 시스템이 뭘 쓰는지 떠올려 보세요. 그게 답입니다.

---

## 2. licenses — "이 오픈소스 라이선스는 막는다"

오픈소스마다 "이렇게 써야 한다"는 법적 조건(라이선스)이 있습니다. 일부는 은행이 쓰기 위험해서 **금지**합니다.

- `denied` (금지): 보통 **AGPL, GPL** 계열을 막습니다. (소스 공개 의무가 강해 은행에 부담)
- `review_required` (검토): **LGPL, MPL** 등. 쓸 수 있지만 확인 후.

💡 **잘 모르면**: 위 예시(AGPL/GPL 금지, LGPL/MPL 검토)가 업계 일반값입니다. 일단 그대로 두고, 나중에 법무/보안팀 기준으로 보정하면 됩니다.

---

## 3. vulnerabilities — "이 위험 등급은 막는다"

오픈소스에서 발견된 보안 취약점은 심각도가 매겨집니다: `critical`(치명) > `high`(높음) > `medium` > `low`.

- `block_severity`: 보통 `critical`, `high` 를 막습니다. (그대로 두면 무난)
- `allow_waiver`: 막힌 걸 예외승인으로 통과시킬 수 있게 할지. 보통 `true`.

---

## 4. allowed_import_methods — "어떤 형태로 내부에 들여오나"

외부망에서 만든 걸 내부망으로 가져오는 방식입니다.

- `소스반입`: 소스코드 통째로 (가장 흔함)
- `artifact반입`: 빌드된 결과물(jar 등)
- `이미지반입`: 컨테이너 이미지
- 잘 모르면 `소스반입` 으로 시작.

---

## 5. approval_roles — "누가 승인하나" (사람 이름 아님, 역할 이름)

- `import_approver`: 반입을 승인하는 **역할/팀** 이름. 예: `보안검토위원회`
- `deploy_approver`: 배포를 승인하는 역할. 예: `변경관리팀`

⚠️ 실제 **사람 이름·사번은 적지 마세요.** "팀/역할" 이름만.

---

## 다 채운 뒤 — 검사 돌리기

```bash
# 1) 분류 빈칸 검사 (예시 파일로 테스트 가능)
gates/check-classification-complete.sh profile.example.json

# 2) 허용 스택 검사
gates/check-allowed-tech-stack.sh profile.example.json policy.yaml
```

✅ 나오면 통과, ❌ 나오면 메시지가 어디를 고치라고 알려줍니다.
