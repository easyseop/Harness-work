# import-gate 하네스 매뉴얼 (처음 보는 사람용)

> 모르는 용어는 `core/GLOSSARY.md`(용어풀이)를 함께 보세요.

---

## 1. 이 하네스가 왜 있나 (비유로)

이건 외부망에서 만든 것을 내부망으로 들여보내기 직전의 **마지막 출국 심사대**입니다.

공항 출국장처럼, 여기서 세 가지를 확인합니다.

- **짐 다 챙겼나** — 반입 묶음에 필요한 게 다 들어있나 (소스·잠금파일·구성요소목록·계약·증거·서명)
- **검사 다 통과했나** — 앞 하네스들의 검사 증거가 전부 통과(passed)인가
- **혼자 도장 찍지 않았나** — 만든 사람과 승인한 사람이 다른가, 예외 승인은 만료 안 됐나

여기를 통과해야만 내부망으로 들어갑니다. 가장 엄격한 관문이라 **예외 승인으로도 우회 불가**입니다.

---

## 2. 안 쓰면 무슨 일이 나나 (실패 사례)

- 검사를 일부 건너뛴 채 반입 → 내부망에서 문제 터짐, 누가 책임인지도 불명확.
- 만든 사람이 **혼자서** 승인까지 해서 들여보냄 → 견제 장치 없음, 사고 시 추적 불가.
- "임시로" 검사를 끈 게 **무기한** 방치됨 → 보안 구멍이 계속 열려 있음.

이 하네스는 위 세 가지를 모두 막습니다.
특히 예외(waiver)는 **만료일이 반드시 있어야** 하고, 만료되면 자동으로 막힙니다.

---

## 3. 실제 예시로 따라가기 (메신저 사례)

`bundle-manifest.messenger.example.yaml` 은 앞 하네스 4개의 증거를 하나로 모은 묶음입니다.

| 구성요소 | 내용 |
|---|---|
| source / lockfile / sbom | 코드·의존성잠금·구성요소목록 |
| contracts | `solution-card.messenger.yaml` (계약) |
| evidence | profile / solution-contract / binding / contract-test-report — 모두 passed |
| attestation | developer=개발팀-A, verifier=품질검증팀, approver=반입승인책임자 |
| waivers | 없음 (`[]`) |

```bash
gates/check-bundle-complete.sh    bundle-manifest.messenger.example.yaml
gates/check-roles-and-waivers.sh  bundle-manifest.messenger.example.yaml
```

음성 예) approver 를 developer 와 같게 하면 → "역할 분리 위반: 만든 사람과 승인자가 같음" 으로 막힘.
만료된 waiver 가 있으면 → "waiver 만료됨" 으로 막힘.

> 실제 HOST·SRV_CODE 값은 이 묶음에도 없습니다. 내부망에서 주입합니다.

---

## 4. 내가 직접 할 일 vs 자동으로 되는 일

| 구분 | 누가 | 무엇을 |
|---|---|---|
| 🟡 직접 | 반입 담당자 | `bundle-manifest.yaml` 에 구성요소·증거·서명 정리 |
| 🟡 직접 | 승인자(별도) | 승인 도장 (만든 사람과 다른 사람) |
| 🟢 자동 | 게이트 | 묶음 완성·증거 통과·역할분리·예외만료 자동 검사 |

> 핵심: 이 관문은 **혼자 통과할 수 없게** 설계돼 있습니다.
> 만든 사람 ≠ 승인한 사람 이 강제됩니다.

---

## 5. 자주 막히는 곳 (FAQ)

**Q. 검사를 급하게 끄고 반입하면 안 되나요?**
A. `--no-verify` 같은 조용한 우회는 금지입니다(INV-6). 꼭 필요하면 **만료일 있는 waiver** 로만,
그것도 승인자 기록과 함께여야 합니다. 만료되면 자동으로 다시 막힙니다.

**Q. 1인 팀이라 만든 사람과 승인자가 같을 수밖에 없어요.**
A. 그래도 역할은 분리해야 합니다(다른 사람이 승인). 조직에 맞게 누가 approver 인지
미리 정해 두세요. 이건 보안·감사 요건이라 우회 불가입니다.

**Q. waiver 는 어떻게 적나요?**
A. `gate`(어떤 검사를 우회), `reason`(왜), `approved_by`(누가 승인), `expires_on`(만료일 YYYY-MM-DD)
네 가지가 모두 필요합니다. 하나라도 빠지면 막힙니다.

**Q. evidence 의 id 는 어디서 오나요?**
A. 앞 하네스들의 manifest 에 적힌 evidence id 입니다 (profile / solution-contract / binding /
contract-test-report 등). 그대로 옮겨 status 를 적으면 됩니다.

**Q. pyyaml 오류가 납니다.**
A. `pip install pyyaml` 후 다시 실행하세요.
