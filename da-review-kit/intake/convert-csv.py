#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# 고정 CSV 양식 → DA검토 INPUT(yaml) 변환  (LLM 불필요, 결정적)
#   CSV 헤더: table,korean,english,attribute,infotype,typelength,pk,nullable
#   표준목록(standard-tables.yaml)을 주면 각 테이블에 standard true/false 를 입힌다.
# 사용: python3 convert-csv.py <design.csv> [standard-tables.yaml] > review-target.yaml
import sys, csv, yaml

csv_path = sys.argv[1]
std_list = None
if len(sys.argv) > 2:
    std_list = set(yaml.safe_load(open(sys.argv[2], encoding="utf-8")).get("standard_tables", []))

tables = {}
with open(csv_path, newline="", encoding="utf-8-sig") as f:
    for row in csv.DictReader(f):
        tn = (row.get("table") or "").strip()
        if not tn: continue
        t = tables.setdefault(tn, {"physical_name": tn, "columns": []})
        col = {
            "korean":  (row.get("korean")  or "").strip(),
            "english": (row.get("english") or "").strip(),
            "infotype":(row.get("infotype")or "").strip(),
            "typelength": (row.get("typelength") or "").strip(),
            "pk": (row.get("pk") or "").strip().upper() in ("Y","TRUE","1"),
            "nullable": (row.get("nullable") or "").strip().upper() in ("Y","TRUE","1"),
        }
        attr = (row.get("attribute") or "").strip()
        if attr: col["attribute"] = attr
        t["columns"].append(col)

for tn, t in tables.items():
    if std_list is not None:
        t["standard"] = tn in std_list      # 사람이 지정한 표준목록 반영

print(yaml.safe_dump({"project": "converted_from_csv", "tables": list(tables.values())},
                     allow_unicode=True, sort_keys=False))
