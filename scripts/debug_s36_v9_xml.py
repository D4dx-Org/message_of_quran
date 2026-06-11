"""Debug verse 36:9 paragraph XML structure."""
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

from docx import Document
from docx.oxml.ns import qn

doc = Document("assets/db/Part III_word.docx")

# Find paragraph index by scanning until we see "36:9"
for i, para in enumerate(doc.paragraphs):
    txt = para.text.strip()
    if "(36:9)" in txt or "36:9" in txt[:15]:
        print(f"=== p{i} ===")
        print(f"  plain text: {txt[:120]!r}")
        print(f"  style: {para.style.name!r}")
        # Show each run with its content and footnote refs
        for j, run in enumerate(para.runs):
            fn_refs = run._r.findall(qn("w:footnoteReference"))
            fn_ids = [r.get(qn("w:id")) for r in fn_refs]
            print(f"  run[{j}]: text={run.text!r}  fn_refs={fn_ids}  font.size={run.font.size}")
        # Show full XML
        print(f"  XML (first 800 chars):")
        import lxml.etree as etree
        print(etree.tostring(para._p, pretty_print=True).decode("utf-8")[:800])
        break
