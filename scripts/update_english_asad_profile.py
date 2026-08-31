"""
update_english_asad_profile.py

Replaces the English Muhammad Asad profile (`authors.html_content`).

That row was titled `<h2>Muhammad Asad</h2>` but held K.C. Saleem's own
biography, so the English "Muhammad Asad" page showed the wrong person
entirely. This puts an English rendering of the Malayalam Asad article
(`malayalam_authors`) there instead, as a stand-in until the printed English
original is supplied. The byline is kept because the article is written in
the first person.

Reads the text from a plain-text file (first line = heading, each following
non-empty line = one paragraph), the same shape
update_malayalam_asad_profile.py takes.

Idempotent: re-running with the same input produces the same HTML.

    python scripts/update_english_asad_profile.py <text-file> <sqlite> [<sqlite> ...]
"""
import html
import io
import sqlite3
import sys


def build_html(text_path):
    lines = [
        l.strip()
        for l in io.open(text_path, encoding="utf-8").read().split("\n")
        if l.strip()
    ]
    if len(lines) < 2:
        raise SystemExit("ABORTED: input needs a heading line plus at least one paragraph")
    heading, paras = lines[0], lines[1:]
    parts = [f"<h2>{html.escape(heading, quote=False)}</h2>"]
    parts += [f"<p>{html.escape(p, quote=False)}</p>" for p in paras]
    return "\n".join(parts), len(paras)


def apply(db_path, content, n_paras):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    row = cur.execute("SELECT id, html_content FROM authors").fetchone()
    if row is None:
        raise SystemExit(f"ABORTED: authors is empty in {db_path}")
    before = len(row[1] or "")
    if row[1] == content:
        print(f"{db_path}: already up to date, skipped")
        conn.close()
        return
    cur.execute("UPDATE authors SET html_content = ? WHERE id = ?", (content, row[0]))
    conn.commit()
    conn.close()
    print(f"{db_path}: authors.html_content {before} -> {len(content)} chars, {n_paras} paragraphs")


if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    content, n_paras = build_html(sys.argv[1])
    for db in sys.argv[2:]:
        apply(db, content, n_paras)
