"""
update_malayalam_asad_profile.py

Replaces the Malayalam Muhammad Asad profile (`malayalam_authors.html_content`)
with the text supplied by the user.

The 21 body paragraphs are byte-for-byte identical to what was already
stored -- verified by diffing before applying -- so the only change is the
heading block:

    old:  <h2>മുഹമ്മദ് അസദിന്‍റെ യാത്രകള്‍</h2>
          <p>മക്കയിലേക്കുള്ള പാതയും</p>
          <p>കെ.സി. സലീം</p>

    new:  <h2>മുഹമ്മദ് അസദ്</h2>

Note this drops the "കെ.സി. സലീം" byline that credited the article's
author; that is what the supplied replacement text contains.

Reads the paragraphs from a plain-text file (first line = heading, each
following non-empty line = one paragraph) so the Malayalam is never
retyped into source.

Idempotent: re-running with the same input produces the same HTML.

    python scripts/update_malayalam_asad_profile.py <text-file> <sqlite> [<sqlite> ...]
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
    row = cur.execute("SELECT id, html_content FROM malayalam_authors").fetchone()
    if row is None:
        raise SystemExit(f"ABORTED: malayalam_authors is empty in {db_path}")
    before = len(row[1] or "")
    if row[1] == content:
        print(f"{db_path}: already up to date, skipped")
        conn.close()
        return
    cur.execute(
        "UPDATE malayalam_authors SET html_content = ? WHERE id = ?", (content, row[0])
    )
    conn.commit()
    conn.close()
    print(
        f"{db_path}: updated id={row[0]} -- {before} -> {len(content)} chars, "
        f"{n_paras} paragraphs"
    )


if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    content, n = build_html(sys.argv[1])
    for path in sys.argv[2:]:
        apply(path, content, n)
