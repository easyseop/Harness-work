#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# 자유/비정형 설계도 → DA검토 INPUT(yaml) 변환  (LLM 필요 — 내부망 LLM 연결 자리)
#   · LLM은 '변환'만 한다 (검사·표준여부 판단 금지).
#   · 출력은 스키마로 검증해 형식 보장(환각 방지).
#   · call_llm() 을 사내 LLM API 호출로 교체하면 동작한다. (현재는 미연결 stub)
# 사용: python3 convert-llm.py <free-design.txt> > review-target.yaml
import sys, os, yaml

HERE = os.path.dirname(os.path.abspath(__file__))
SCHEMA = open(os.path.join(HERE, "..", "schemas", "db-design.schema.json"), encoding="utf-8").read()

PROMPT = """너는 형식 변환기다. 아래 [설계도]를 [스키마]에 맞는 YAML로만 출력하라.
규칙:
- 설계도에 있는 값만 사용. 없는 값은 추측·창작하지 말고 빈 문자열("")로 둔다.
- standard(표준여부)는 절대 판단하지 말 것. (별도 단계에서 사람이 지정)
- 컬럼은 korean/english/infotype/typelength/pk/nullable 키로.
- 설명 문장 없이 YAML 본문만 출력.

[스키마]
{schema}

[설계도]
{raw}
"""

def call_llm(prompt: str) -> str:
    # ── 여기에 사내 내부망 LLM API 호출을 연결하세요 ──
    #   예) return internal_llm.complete(prompt, temperature=0)
    raise NotImplementedError("내부망 LLM API 미연결: call_llm() 을 사내 엔드포인트로 교체하세요.")

def validate(doc) -> bool:           # 형식 보장(스키마 핵심만 결정적으로 확인)
    assert isinstance(doc, dict) and isinstance(doc.get("tables"), list), "tables 배열 필요"
    for t in doc["tables"]:
        assert (t.get("physical_name") or "").strip(), "physical_name 필요"
        for c in (t.get("columns") or []):
            for k in ("korean", "english", "infotype"):
                assert k in c, f"컬럼 필수키 '{k}' 누락"
    return True

def convert(raw_text: str):
    out = call_llm(PROMPT.format(schema=SCHEMA, raw=raw_text))
    doc = yaml.safe_load(out)
    validate(doc)                    # LLM 출력 형식 검증 → 통과해야 다음 단계로
    return doc

if __name__ == "__main__":
    raw = open(sys.argv[1], encoding="utf-8").read()
    print(yaml.safe_dump(convert(raw), allow_unicode=True, sort_keys=False))
