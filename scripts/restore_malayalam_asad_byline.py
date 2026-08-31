"""
restore_malayalam_asad_byline.py

Restores the "കെ.സി. സലീം" byline to the Malayalam Muhammad Asad profile
(`malayalam_authors.html_content`).

update_malayalam_asad_profile.py replaced the old three-line heading block

    <h2>മുഹമ്മദ് അസദിന്‍റെ യാത്രകള്‍</h2>
    <p>മക്കയിലേക്കുള്ള പാതയും</p>
    <p>കെ.സി. സലീം</p>

with the single supplied heading `<h2>മുഹമ്മദ് അസദ്</h2>`, which dropped the
byline. The article is written in the first person ("എന്‍റെ പിതാവ് മൂസാ
നാസിഹിന്") while the same page names Asad's father as Kiva Weiss, so without
the byline those sentences have no speaker. This puts the byline back
directly under the new heading, leaving the heading and the body untouched.

Idempotent: aborts (without writing) if the byline is already there.

    python scripts/restore_malayalam_asad_byline.py <sqlite> [<sqlite> ...]
"""
import sqlite3
import sys

HEADING = "<h2>മുഹമ്മദ് അസദ്</h2>"
BYLINE = "<p>കെ.സി. സലീം</p>"


def apply(db_path):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    row = cur.execute("SELECT id, html_content FROM malayalam_authors").fetchone()
    if row is None:
        raise SystemExit(f"ABORTED: malayalam_authors is empty in {db_path}")
    content = row[1] or ""
    if BYLINE in content:
        print(f"{db_path}: byline already present, skipped")
        conn.close()
        return
    if not content.startswith(HEADING + "\n"):
        raise SystemExit(
            f"ABORTED: {db_path} does not start with the expected heading; "
            "nothing written"
        )
    updated = content.replace(HEADING + "\n", HEADING + "\n" + BYLINE + "\n", 1)
    cur.execute(
        "UPDATE malayalam_authors SET html_content = ? WHERE id = ?",
        (updated, row[0]),
    )
    conn.commit()
    conn.close()
    print(f"{db_path}: byline restored ({len(content)} -> {len(updated)} chars)")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    for db in sys.argv[1:]:
        apply(db)
