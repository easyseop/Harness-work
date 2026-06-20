# 안전수칙 (SAFE-OR-NOT) — config-secret

이 하네스는 "진짜 값"을 다루기 직전 단계라서, 안전수칙이 특히 중요합니다.

---

## ✅ 외부망에 적어도 되는 것

- 빈 자리 **이름** (`MESSENGER_HOST`, `MESSENGER_SRV_CODE`)
- 빈 자리 **설명·종류·사는 곳** (config/secret, external-ok/internal-only)
- config(안 민감)의 **기본값** (타임아웃 `3000`, 인코딩 `UTF-8`, 경로 `/HMemoServiceUtf8`)
- `source` 의 **설명** (예: "내부망 환경설정에서 주입") — 어디서 오는지 *설명*만

---

## ❌ 외부망에 적으면 안 되는 것 (진짜 값)

- 실제 **HOST·IP·URL** (`10.x.x.x`, `http://...실제주소`)
- 실제 **SRV_CODE 값**, 비밀번호, 토큰, API 키
- **개인키·인증서** 내용
- 실제 직원번호·고객정보

> 핵심: 여기엔 "빈 자리의 **이름표**"만 적습니다. "빈 자리에 들어갈 **진짜 값**"은
> 외부망 어디에도 적지 않습니다. 진짜 값은 내부망 반입 때만 주입합니다.

## 예시로 감 잡기

| 쓰려는 내용 | 판단 |
|---|---|
| `name: MESSENGER_HOST` | ✅ 안전 (이름표) |
| `kind: secret`, `zone: internal-only` | ✅ 안전 |
| `default: 3000` (config 타임아웃) | ✅ 안전 |
| `default: "http://10.20.30.40/..."` | ❌ 금지 (진짜 값) |
| `source: 비밀 저장소에서 주입` | ✅ 안전 (설명) |
| `source: "IQM001"` (진짜 코드) | ❌ 금지 |

## 게이트가 지켜 줍니다

- `check-no-hardcoded-values` — 코드/설정에 진짜 값이 박히면 **차단** (우회 불가)
- `check-bindings-complete` — secret 에 기본값이 있거나 internal-only 가 아니면 차단
