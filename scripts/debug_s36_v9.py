import re, sys, io
from docx import Document
from docx.oxml.ns import qn

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

path = "assets/db/Part III_word.docx"
doc = Document(path)

VRE = re.compile(r"^\[?\(?(\d+)[-.:;]\s*(\d+)\)?\]?\s*")
in_s36 = False
cnt = 0
for i, para in enumerate(doc.paragraphs):
    txt = para.text.strip()
    # Get effective font size (try runs then style)
    sz = 0
    for run in para.runs:
        if run.font.size:
            sz = round(run.font.size.pt, 1)
            break
    if sz == 0 and para.style.font.size:
        sz = round(para.style.font.size.pt, 1)

    if "36:" in txt and not in_s36:
        in_s36 = True
        print(f"Entered S36 at p{i} sz={sz}: {txt[:60]!r}")
    if in_s36 and "37:" in txt:
        print(f"Left S36 at p{i}: {txt[:60]!r}")
        break
    if in_s36 and sz in (9.5, 12.0):
        cnt += 1
        m = VRE.match(txt)
        print(f"p{i} sz={sz} match={bool(m)} txt={txt[:80]!r}")
