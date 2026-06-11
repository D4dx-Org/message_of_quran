"""
Targeted analysis to find footnote markers and footnote paragraphs in Part III_word.docx
"""
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

from docx import Document
from docx.oxml.ns import qn

doc_path = os.path.join(os.path.dirname(__file__), '..', 'assets', 'db', 'Part III_word.docx')
doc = Document(doc_path)
paras = doc.paragraphs

def get_sz(para):
    """Get font size of first non-empty run, or paragraph default"""
    for run in para.runs:
        if run.font.size:
            return run.font.size.pt
    if para.style.font.size:
        return para.style.font.size.pt
    return None

def is_superscript(run):
    """Check if a run has superscript formatting"""
    # Check run-level superscript
    rPr = run._r.find(qn('w:rPr'))
    if rPr is not None:
        vertAlign = rPr.find(qn('w:vertAlign'))
        if vertAlign is not None:
            val = vertAlign.get(qn('w:val'))
            if val == 'superscript':
                return True
    return False

print("=" * 70)
print("CHECKING FOR SUPERSCRIPT RUNS IN VERSE PARAGRAPHS")
print("=" * 70)

superscript_paras = []
for i, para in enumerate(paras):
    text = para.text.strip()
    if not text:
        continue
    style = para.style.name if para.style else 'None'
    sz = get_sz(para)
    # Only look at 9.5pt paragraphs (verse translations)
    if sz and abs(sz - 9.5) < 0.5:
        for run in para.runs:
            if is_superscript(run) and run.text.strip():
                superscript_paras.append((i, text[:80], run.text))
                break  # just mark first superscript

if superscript_paras:
    print(f"Found {len(superscript_paras)} verse paragraphs with superscript runs (first 20):")
    for p in superscript_paras[:20]:
        print(f"  [{p[0]:04d}] superscript='{p[2]}' | text: {p[1]}")
else:
    print("No superscript runs found in 9.5pt paragraphs")

# Also check ALL paragraphs for superscript
print("\n" + "=" * 70)
print("ALL PARAGRAPHS WITH SUPERSCRIPT RUNS (first 30)")
print("=" * 70)
all_super = []
for i, para in enumerate(paras):
    text = para.text.strip()
    if not text:
        continue
    sz = get_sz(para)
    for run in para.runs:
        if is_superscript(run) and run.text.strip():
            all_super.append((i, sz, text[:80], run.text))
            break

if all_super:
    print(f"Found {len(all_super)} paragraphs with superscript runs:")
    for p in all_super[:30]:
        print(f"  [{p[0]:04d}] sz={p[1]} | superscript='{p[3]}' | text: {p[2]}")
else:
    print("No superscript runs found in any paragraph!")

# Look at paragraph [2502] and surroundings
print("\n" + "=" * 70)
print("CONTEXT AROUND PARAGRAPH [2502]")
print("=" * 70)
for i in range(2495, 2520):
    if i < len(paras):
        para = paras[i]
        text = para.text.strip()
        style = para.style.name if para.style else 'None'
        sz = get_sz(para)
        print(f"[{i:04d}] style='{style}' sz={sz} | {text[:120]}")

# Look at all small-font paragraphs that might be footnotes
print("\n" + "=" * 70)
print("PARAGRAPHS WITH UNUSUAL FONT SIZES (not 8, 9, 9.5, 16, 18)")
print("=" * 70)
known_sizes = {8.0, 9.0, 9.5, 16.0, 18.0}
for i, para in enumerate(paras[162:], start=162):
    text = para.text.strip()
    if not text:
        continue
    sz = get_sz(para)
    if sz and sz not in known_sizes and sz not in {None}:
        style = para.style.name if para.style else 'None'
        print(f"[{i:04d}] sz={sz}pt style='{style}' | {text[:80]}")

# Check XML of paragraph [2502] directly
print("\n" + "=" * 70)
print("XML of paragraph [2502] (first 500 chars)")
print("=" * 70)
import lxml.etree as etree
print(etree.tostring(paras[2502]._element, pretty_print=True).decode('utf-8', errors='replace')[:500])
