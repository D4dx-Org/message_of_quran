"""
update_works_of_reference.py

Replaces the body of the References section (`worksofreference.html_content`)
with the text supplied by the user.

The section's existing HTML idiom is kept: an <h2> heading followed by one
<p> per paragraph, with each bibliography entry's short lookup key wrapped
in <strong>. Those keys are the names the explanatory notes cite ("see
Asas", "Fath al-Bari", etc.), so they are worth keeping visually distinct.

Bolding is evidence-based, never invented: a leading key is wrapped only
when that exact key already appeared inside <strong> in the stored
content AND the new line begins with it. Lines supplied without a
recognisable key are stored plain, exactly as given.

The <h2> heading is left as it was ("Works of Reference"); the supplied
text carried "REFERENCES" only as a section label.

Reads the body from a plain-text file (one paragraph per non-empty line)
so the copy is never retyped into source. Idempotent.

    python scripts/update_works_of_reference.py <text-file> <sqlite> [<sqlite> ...]
"""
import html
import io
import re
import sqlite3
import sys


def build(text_path, existing_html):
    heading_m = re.search(r"<h2>(.*?)</h2>", existing_html, re.S)
    if not heading_m:
        raise SystemExit("ABORTED: no <h2> heading found in the stored content")
    heading = heading_m.group(1)

    known = sorted(
        set(re.findall(r"<strong>(.*?)</strong>", existing_html)), key=len, reverse=True
    )

    lines = [
        l.strip()
        for l in io.open(text_path, encoding="utf-8").read().split("\n")
        if l.strip()
    ]
    if not lines:
        raise SystemExit("ABORTED: input file is empty")

    parts = [f"<h2>{heading}</h2>"]
    bolded = 0
    for line in lines:
        key = next(
            (k for k in known if line.startswith(k + " ") or line.startswith(k + ",")),
            None,
        )
        if key:
            rest = line[len(key) :]
            parts.append(
                f"<p><strong>{html.escape(key, quote=False)}</strong>"
                f"{html.escape(rest, quote=False)}</p>"
            )
            bolded += 1
        else:
            parts.append(f"<p>{html.escape(line, quote=False)}</p>")
    return "\n".join(parts), len(lines), bolded


def apply(db_path, text_path):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    row = cur.execute("SELECT id, html_content FROM worksofreference").fetchone()
    if row is None:
        raise SystemExit(f"ABORTED: worksofreference is empty in {db_path}")

    content, n_paras, bolded = build(text_path, row[1])
    if row[1] == content:
        print(f"{db_path}: already up to date, skipped")
        conn.close()
        return
    before = len(row[1] or "")
    cur.execute(
        "UPDATE worksofreference SET html_content = ? WHERE id = ?", (content, row[0])
    )
    conn.commit()
    conn.close()
    print(
        f"{db_path}: updated id={row[0]} -- {before} -> {len(content)} chars, "
        f"{n_paras} paragraphs, {bolded} keys bolded"
    )


if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    for path in sys.argv[2:]:
        apply(path, sys.argv[1])
