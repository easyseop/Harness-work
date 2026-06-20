# 채우기 설명서 (FILL-GUIDE) — config-secret

`binding.template.yaml` 을 복사해 빈 자리를 1개씩 채웁니다.
실제 예시는 `binding.messenger.example.yaml` 을 보세요.

---

## binding — 기본 정보

| 칸 | 뜻 | 예시 |
|---|---|---|
| `for_solution` | 어떤 솔루션 카드의 빈 자리인지 (별칭) | `messenger` |
| `owner_role` | 이 바인딩 책임 **역할** (사람 이름 X) | `내부플랫폼팀` |

## variables — 빈 자리 1개당

| 칸 | 뜻 | 규칙 |
|---|---|---|
| `name` | 빈 자리 이름 | 대문자_스네이크. 예: `MESSENGER_HOST` |
| `kind` | 종류 | `config`(안 민감) / `secret`(민감) |
| `zone` | 사는 곳 | `external-ok` / `internal-only` |
| `required` | 꼭 필요한가 | `true` / `false` |
| `default` | 기본값 | config 만 가능. **secret 은 항상 비움(null)** |
| `source` | 진짜 값을 어디서 가져오나 | 설명만. **실제 값 X** |
| `description` | 한 줄 설명 | |

---

## config vs secret — 어떻게 고르나

- **밖에 알려지면 곤란한 값**(HOST·IP·접속코드·비밀번호·토큰·인증서) → `secret`
  → 반드시 `zone: internal-only`, `default: null`
- **동작 설정값**(타임아웃·재시도·인코딩·경로) → `config`
  → `external-ok` 가능, 기본값 둬도 됨

> 헷갈리면 secret 으로 두는 게 안전합니다. (더 엄격하게 보호됨)

## 코드 쪽은 어떻게?

코드에는 진짜 값 대신 빈 자리만 씁니다.
```python
HOST = os.environ["MESSENGER_HOST"]   # O
HOST = "http://10.20.30.40/..."        # X (게이트가 차단)
```

## 다 채운 뒤 — 검사 돌리기

```bash
gates/check-bindings-complete.sh   binding.yaml
gates/check-no-hardcoded-values.sh ./src      # 코드 폴더
```
