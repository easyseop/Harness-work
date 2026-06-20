import markdown, html, os

DOCS = [
    ("용어풀이 · GLOSSARY", "core/GLOSSARY.md"),
    ("코어 · CLAUDE.md", "core/CLAUDE.md"),
    ("코어 · AGENTS.md", "core/AGENTS.md"),
    ("코어 · ARCHITECTURE_INVARIANTS.md", "core/ARCHITECTURE_INVARIANTS.md"),
    ("규격 · Spine & Manifest 규격", "00-spine-and-manifest-spec.md"),
    ("키트 · README", "policy-profile-kit/README.md"),
    ("키트 · FILL-GUIDE (작성설명서)", "policy-profile-kit/FILL-GUIDE.md"),
    ("키트 · SAFE-OR-NOT (안전수칙)", "policy-profile-kit/SAFE-OR-NOT.md"),
]
base = "/tmp/harness-out"
md = markdown.Markdown(extensions=["tables", "fenced_code", "toc", "sane_lists"])

CSS = """
body{font-family:-apple-system,'Apple SD Gothic Neo','Malgun Gothic',NanumGothic,sans-serif;
max-width:860px;margin:0 auto;padding:24px;line-height:1.7;color:#222;background:#fafafa}
h1{border-bottom:3px solid #5555aa;padding-bottom:8px;margin-top:8px}
h2{border-bottom:1px solid #ddd;padding-bottom:6px;margin-top:32px;color:#33366a}
h3{color:#444;margin-top:24px}
code{background:#eef;padding:2px 6px;border-radius:4px;font-size:.9em}
pre{background:#1e1e2e;color:#e6e6e6;padding:14px;border-radius:8px;overflow-x:auto}
pre code{background:none;color:inherit;padding:0}
table{border-collapse:collapse;width:100%;margin:14px 0}
th,td{border:1px solid #ccc;padding:8px 10px;text-align:left}
th{background:#eef0ff}
blockquote{border-left:4px solid #5555aa;margin:14px 0;padding:8px 16px;background:#eef;color:#333}
.doc{background:#fff;border:1px solid #e0e0e0;border-radius:12px;padding:28px;margin:28px 0;
box-shadow:0 1px 4px rgba(0,0,0,.06)}
.toc-top{background:#fff;border:2px solid #5555aa;border-radius:12px;padding:20px 28px;margin:20px 0}
.toc-top a{display:block;padding:4px 0;color:#33366a;text-decoration:none}
.toc-top a:hover{text-decoration:underline}
hr{border:none;border-top:1px dashed #ccc;margin:24px 0}
"""

parts = ['<!DOCTYPE html><html lang="ko"><head><meta charset="utf-8">',
         '<meta name="viewport" content="width=device-width,initial-scale=1">',
         '<title>은행 반입 하네스 — 문서 모음</title><style>'+CSS+'</style></head><body>']
parts.append('<h1>은행 반입 하네스 — 문서 모음</h1>')
parts.append('<p style="color:#777">작성일 2026-06-17 · 브라우저에서 열어 보세요. 표·코드블록이 렌더링됩니다.</p>')
# TOC
parts.append('<div class="toc-top"><b>목차</b>')
for i,(title,_) in enumerate(DOCS):
    parts.append(f'<a href="#doc{i}">{html.escape(title)}</a>')
parts.append('</div>')
# docs
for i,(title,path) in enumerate(DOCS):
    full=os.path.join(base,path)
    text=open(full,encoding="utf-8").read()
    md.reset()
    body=md.convert(text)
    parts.append(f'<div class="doc" id="doc{i}">{body}</div>')
parts.append('</body></html>')
open(f"{base}/하네스-문서모음.html","w",encoding="utf-8").write("\n".join(parts))
print("ok", os.path.getsize(f"{base}/하네스-문서모음.html"), "bytes")
