"""
update_malayalam_appendices.py

Replaces the bodies of the four Malayalam appendices with the revised text
supplied on 2026-09-01.

All four rows already existed from an earlier revision; only `body` changes.
`number`, `roman_numeral`, `title` and the page range are left alone, so the
rows keep their place in the book.

Reads a plain-text file in which each appendix starts with a `### <number>`
line and its paragraphs are separated by blank lines. Paragraphs are stored
joined by a blank line, matching how the existing rows are stored (the app
splits on that to lay the text out).

Idempotent: a body already equal to the new text is skipped.

    python scripts/update_malayalam_appendices.py <text-file> <sqlite> [<sqlite> ...]
"""
import io
import re
import sqlite3
import sys

EXPECTED = {1, 2, 3, 4}


def parse(text_path):
    raw = io.open(text_path, encoding="utf-8").read()
    chunks = re.split(r"^### (\d+)\s*$", raw, flags=re.MULTILINE)
    # re.split leaves a leading empty chunk, then alternating number/body
    bodies = {}
    for number, body in zip(chunks[1::2], chunks[2::2]):
        paragraphs = [p.strip() for p in body.strip().split("\n\n") if p.strip()]
        if not paragraphs:
            raise SystemExit(f"ABORTED: appendix {number} has no paragraphs")
        bodies[int(number)] = "\n\n".join(paragraphs)
    if set(bodies) != EXPECTED:
        raise SystemExit(f"ABORTED: expected appendices {sorted(EXPECTED)}, got {sorted(bodies)}")
    return bodies


def apply(db_path, bodies):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    rows = dict(cur.execute("SELECT number, body FROM malayalam_appendices").fetchall())
    if set(rows) != EXPECTED:
        raise SystemExit(f"ABORTED: {db_path} holds appendices {sorted(rows)}")
    changed = skipped = 0
    report = []
    for number in sorted(EXPECTED):
        before, after = rows[number] or "", bodies[number]
        if before == after:
            skipped += 1
            continue
        cur.execute(
            "UPDATE malayalam_appendices SET body = ? WHERE number = ?", (after, number)
        )
        changed += 1
        report.append(
            f"  {number}: {len(before)} -> {len(after)} chars, "
            f"{before.count(chr(10) * 2) + 1} -> {after.count(chr(10) * 2) + 1} paragraphs"
        )
    conn.commit()
    conn.close()
    print(f"{db_path}: {changed} updated, {skipped} already current")
    print("\n".join(report))


if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    bodies = parse(sys.argv[1])
    for db in sys.argv[2:]:
        apply(db, bodies)
