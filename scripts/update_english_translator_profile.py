"""
update_english_translator_profile.py

Replaces the English translator profile shown by the Translator screen
(`translator` table, read via english_translator_db_helper.dart).

That screen renders the row as:
    name     -> heading
    bio      -> split on newlines, one paragraph per non-empty line
    address  -> rendered as "Address: ..."
    email    -> rendered as "Email: ..."
(`role` is stored but not displayed.)

So the supplied copy is split accordingly: the "Address:" and "Email:"
lines go into their own columns without the label, since the screen adds
it, and everything above them becomes the bio. `name` ("K.C. Saleem")
and `role` ("Translator") are left as they are -- the opening line
"K.C. Saleem, Translator of ..." is kept as the first bio paragraph so
it is actually visible, since `name` is only a short heading.

Reads the bio from a plain-text file so the copy is never retyped into
source. Idempotent.

    python scripts/update_english_translator_profile.py <bio-file> <sqlite> [<sqlite> ...]
"""
import io
import sqlite3
import sys

ADDRESS = "Shadan, Check Post Road, Puthiyangadi, Kozhikode - 673021. Kerala. India."
EMAIL = "kcsaleem07@gmail.com"


def apply(db_path, bio):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    row = cur.execute(
        "SELECT id, name, role, bio, email, address FROM translator"
    ).fetchone()
    if row is None:
        raise SystemExit(f"ABORTED: translator table is empty in {db_path}")

    if (row[3], row[4], row[5]) == (bio, EMAIL, ADDRESS):
        print(f"{db_path}: already up to date, skipped")
        conn.close()
        return

    before = len(row[3] or "")
    cur.execute(
        "UPDATE translator SET bio = ?, email = ?, address = ? WHERE id = ?",
        (bio, EMAIL, ADDRESS, row[0]),
    )
    conn.commit()
    conn.close()
    paras = len([p for p in bio.split("\n") if p.strip()])
    print(
        f"{db_path}: updated id={row[0]} -- bio {before} -> {len(bio)} chars, "
        f"{paras} paragraphs (name={row[1]!r}, role={row[2]!r} unchanged)"
    )


if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    bio = io.open(sys.argv[1], encoding="utf-8").read().strip()
    if not bio:
        raise SystemExit("ABORTED: bio file is empty")
    for path in sys.argv[2:]:
        apply(path, bio)
