#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# 모의 스트레스 테스트: 정답을 아는 케이스 100개를 생성→게이트 실행→기대 vs 실제 대조
#  - 정상 케이스: 표준대로 생성 → 통과 기대
#  - 위반 케이스: 한 군데만 고의로 깨뜨림 → 그 사유로 반송 기대
#  결과: 오탐(정상인데 반송)·누락(위반인데 통과)·사유불일치 를 집계
import os, sys, json, random, subprocess, tempfile
import yaml

random.seed(7)
KIT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
META = yaml.safe_load(open(os.path.join(KIT, "meta/standard-meta.yaml"), encoding="utf-8"))
words = META["standard_words"]; domains = META["domains"]
end_exc = META.get("end_word_exceptions", {})
apps = list(META["naming"]["valid_app_codes"]); subs = list(META["naming"]["valid_subgroup_codes"])
ic = META["instance_code"]

# ---- 게이트와 동일한 분해 로직(정상 케이스를 게이트 기준에 맞춰 생성하기 위함) ----
def tokenize(kr):
    keys = sorted(words, key=len, reverse=True); toks, i = [], 0
    while i < len(kr):
        for k in keys:
            if kr.startswith(k, i): toks.append(k); i += len(k); break
        else: return None
    return toks
def find_ew(kr):
    c = [w for w in list(domains)+list(end_exc) if kr.endswith(w)]
    return max(c, key=len) if c else None

def valid_column():
    while True:
        mods = random.sample(list(words), k=random.randint(1, 2))
        dom = random.choice(list(domains))
        kr = "".join(mods) + dom
        if len(kr) > META["column"]["korean_max_chars_server"]: continue
        ew = find_ew(kr); real = end_exc.get(ew, ew); pre = kr[:-len(ew)]
        toks = tokenize(pre) if pre else []
        if toks is None or real not in domains: continue
        en = "_".join([words[w] for w in toks] + [domains[real]["abbr"]])
        lens = domains[real]["lengths"]
        it = real + (random.choice(lens) if lens else "")
        return {"korean": kr, "english": en, "infotype": it, "typelength": "CHAR(x)",
                "pk": False, "nullable": False, "_dom": real}

AUDIT = [
    {"korean":"시스템최종처리일시","english":"SYS_LST_PRC_DTM","infotype":"일시14","typelength":"CHAR(14)","pk":False,"nullable":False},
    {"korean":"시스템최종사용자번호","english":"SYS_LST_USR_NO","infotype":"번호","typelength":"CHAR(20)","pk":False,"nullable":False},
]
def valid_table():
    name = "T"+random.choice("HS")+random.choice(apps)+random.choice(subs)+f"{random.randint(0,99):02d}"
    cols = [valid_column() for _ in range(random.randint(2,3))]
    cols[0]["pk"] = True                      # PK 보장
    cols += [dict(a) for a in AUDIT]
    return {"physical_name": name, "columns": cols, "relationships": []}

cases = []   # (id, kind, input_dict, expect_status, expect_reason_substr)

# ===== 정상 DB설계서 40 =====
for i in range(40):
    cases.append((f"db_ok_{i}", "physical", {"project":f"OK{i}","tables":[valid_table()]}, "passed", None))

# ===== 위반 DB설계서 40 (8유형 x 5) =====
def base(): return {"project":"BAD","tables":[valid_table()]}
muts = []
for i in range(5):
    t=base(); t["tables"][0]["physical_name"]="TZ"+t["tables"][0]["physical_name"][2:]; muts.append((t,"명명규칙","bad_sys"))
for i in range(5):
    t=base(); n=t["tables"][0]["physical_name"]; t["tables"][0]["physical_name"]=n[:2]+"ZZZ"+n[5:]; muts.append((t,"어플리케이션코드","bad_app"))
for i in range(5):
    t=base(); n=t["tables"][0]["physical_name"]; t["tables"][0]["physical_name"]=n[:5]+"ZZ"+n[7:]; muts.append((t,"업무소그룹","bad_sg"))
for i in range(5):
    t=base(); t["tables"][0]["columns"][0]["korean"]="임시"+t["tables"][0]["columns"][0]["korean"]; muts.append((t,"비표준단어","nonstd_mod"))
for i in range(5):
    t=base(); c=t["tables"][0]["columns"][0]; c["korean"]="계좌상태"; c["english"]="ACCT_STAT"; muts.append((t,"도메인(인포타입)으로 끝나지","nondomain_end"))
for i in range(5):
    t=base(); t["tables"][0]["columns"][0]["english"]="XXX_WRONG"; muts.append((t,"영문명","wrong_en"))
for i in range(5):
    t=base();
    # 성별/금액 처럼 길이제한 도메인 컬럼을 넣고 잘못된 길이
    t["tables"][0]["columns"][0]={"korean":"고객성별","english":"CUST_SEX","infotype":"성별99","typelength":"CHAR(99)","pk":True,"nullable":False}
    muts.append((t,"인포타입 길이","bad_itlen"))
for i in range(5):
    t=base()
    for c in t["tables"][0]["columns"]: c["pk"]=False
    muts.append((t,"PK","no_pk"))
for j,(t,reason,tag) in enumerate(muts):
    cases.append((f"db_bad_{tag}_{j}", "physical", t, "failed", reason))

# ===== 인스턴스코드 정의서: 정상 10 / 위반 10 =====
def valid_instance():
    mods = random.sample(list(words), k=random.randint(1,2))
    ending = random.choice(ic["name_endings"])
    nm = "".join(mods)+ending
    # 단독금지/끝말 자체로 깨지지 않게: 수식어 있고 끝말 정상
    return nm, ending
def inst_doc(names_vals):
    inames=[]; cvals=[]
    for nm,vals in names_vals:
        inames.append({"app_code":"BFA","app_name":"공통","instance_name":nm,"code_length":1,
                       "terminal_deploy":0,"external_data":0,"list_table_managed":0})
        for code,cont in vals: cvals.append({"instance_name":nm,"code":code,"content":cont})
    return {"project":"INST","instance_names":inames,"code_values":cvals}

for i in range(10):
    nm,ending = valid_instance()
    if ending in ic["yn_endings"]: vals=[("0","부"),("1","여")]
    else: vals=[("0","해당무"),("1","정상")]
    cases.append((f"inst_ok_{i}","instance", inst_doc([(nm,vals)]), "passed", None))

inst_bad=[]
for i in range(2):  # 비표준 수식어
    inst_bad.append((inst_doc([("임시구분코드",[("0","해당무")])]),"비표준단어"))
for i in range(2):  # 단독금지
    inst_bad.append((inst_doc([("여부",[("0","부")])]),"단독사용금지"))
for i in range(2):  # 끝말 위반
    inst_bad.append((inst_doc([("계좌상태",[("0","x")])]),"끝말 규칙"))
for i in range(2):  # 여부 0/1 초과
    inst_bad.append((inst_doc([("신용여부",[("0","부"),("1","여"),("2","기타")])]),"0/1 만 허용"))
for i in range(2):  # 시트1에 없음
    d=inst_doc([("거래구분코드",[("0","해당무")])]); d["code_values"].append({"instance_name":"유령여부","code":"0","content":"부"})
    inst_bad.append((d,"시트1"))
for j,(d,reason) in enumerate(inst_bad):
    cases.append((f"inst_bad_{j}","instance", d, "failed", reason))

# ===== 실행 & 대조 =====
def run(gate, doc):
    with tempfile.NamedTemporaryFile("w", suffix=".yaml", delete=False, encoding="utf-8") as f:
        yaml.safe_dump(doc, f, allow_unicode=True); path=f.name
    out=path+".json"
    subprocess.run(["bash", os.path.join(KIT,f"gates/{gate}.sh"), path],
                   env={**os.environ,"DA_OUT":out}, capture_output=True)
    r=json.load(open(out,encoding="utf-8")); os.remove(path); os.remove(out); return r

gate_for={"physical":"check-physical","instance":"check-instance-code"}
false_pos=[]; false_neg=[]; reason_mismatch=[]; ok=0
by_reason={}
for cid,kind,doc,exp_status,exp_reason in cases:
    r=run(gate_for[kind], doc)
    act=r["status"]; msgs=[f["message"] for f in r["findings"]]
    if act==exp_status: ok+=1
    if exp_status=="passed" and act=="failed":
        false_pos.append((cid, msgs))
    if exp_status=="failed" and act=="passed":
        false_neg.append((cid, doc))
    if exp_status=="failed" and act=="failed":
        hit = any(exp_reason in m for m in msgs)
        by_reason.setdefault(exp_reason,[0,0]); by_reason[exp_reason][1]+=1
        if hit: by_reason[exp_reason][0]+=1
        else: reason_mismatch.append((cid, exp_reason, msgs))

print(f"총 {len(cases)}건  (정상 50 / 위반 50)")
print(f"기대=실제 일치: {ok}/{len(cases)}")
print(f"오탐(정상인데 반송) : {len(false_pos)}건")
print(f"누락(위반인데 통과) : {len(false_neg)}건")
print(f"사유 불일치(반송됐으나 다른 사유) : {len(reason_mismatch)}건")
print("\n[위반 유형별 사유 정확도]  (사유적중/반송수)")
for rsn,(hit,tot) in sorted(by_reason.items()):
    print(f"  {rsn:28s} {hit}/{tot}")
if false_pos:
    print("\n[오탐 상세]")
    for cid,msgs in false_pos[:10]: print(f"  {cid}: {msgs}")
if false_neg:
    print("\n[누락 상세]")
    for cid,_ in false_neg[:10]: print(f"  {cid}")
if reason_mismatch:
    print("\n[사유 불일치 상세]")
    for cid,exp,msgs in reason_mismatch[:10]: print(f"  {cid}  기대사유='{exp}'  실제={msgs}")
