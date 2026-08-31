"""
update_about_us_english.py

Replaces the English About Us body (`about_us.description`) with the text
supplied by the user. Only `description` is touched -- `title`
("About Us") and `signed_by` ("D4DX INNOVATIONS LLP") are left as they
are.

The column holds plain text, not HTML: paragraphs are separated by blank
lines and the reader renders it directly (with Linkify applied for URLs),
so the replacement is stored the same way.

Reads the body from a plain-text file so the copy is never retyped into
source. Idempotent: re-running with the same input is a no-op.

    python scripts/update_about_us_english.py <text-file> <sqlite> [<sqlite> ...]
"""
import io
import sqlite3
import sys


def apply(db_path, body):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    row = cur.execute("SELECT id, title, description, signed_by FROM about_us").fetchone()
    if row is None:
        raise SystemExit(f"ABORTED: about_us is empty in {db_path}")
    if row[2] == body:
        print(f"{db_path}: already up to date, skipped")
        conn.close()
        return
    before = len(row[2] or "")
    cur.execute("UPDATE about_us SET description = ? WHERE id = ?", (body, row[0]))
    conn.commit()
    conn.close()
    print(
        f"{db_path}: updated id={row[0]} -- description {before} -> {len(body)} chars "
        f"(title={row[1]!r}, signed_by={row[3]!r} unchanged)"
    )


if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    body = io.open(sys.argv[1], encoding="utf-8").read().strip()
    if not body:
        raise SystemExit("ABORTED: input file is empty")
    for path in sys.argv[2:]:
        apply(path, body)
