"""
update_malayalam_translator_profile.py

Replaces the Malayalam translator profile shown by the Translator screen
(`malayalam_about_translator`, read via about_author_db_helper.dart).

That screen (translator_screen.dart) renders the row as:
    name   -> heading
    bio    -> split on newlines, one paragraph per non-empty line
    mobile -> printed on its own line, unlabelled
    email  -> printed as "E-mail: ..."
(`role` is stored but not displayed.)

Note the address is what the `mobile` column actually holds -- the
supplied copy has the "വിലാസം: ..." sentence at the end of the last
paragraph, so it is moved into `mobile` instead of being left in the
bio; leaving it in both would print the address twice.

Reads the bio from a plain-text file so the copy is never retyped into
source. `name` and `role` are left untouched. Idempotent.

    python scripts/update_malayalam_translator_profile.py <bio-file> <sqlite> [<sqlite> ...]
"""
import io
import sqlite3
import sys

ADDRESS = "വിലാസം: ശാദാൻ, ചെക്ക് പോസ്റ്റ് റോഡ്, പുതിയങ്ങാടി, കോഴിക്കോട്-673021."
EMAIL = "kcsaleem07@gmail.com."


def apply(db_path, bio):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    row = cur.execute(
        "SELECT id, name, role, bio, email, mobile FROM malayalam_about_translator"
    ).fetchone()
    if row is None:
        raise SystemExit(f"ABORTED: malayalam_about_translator is empty in {db_path}")

    if (row[3], row[4], row[5]) == (bio, EMAIL, ADDRESS):
        print(f"{db_path}: already up to date, skipped")
        conn.close()
        return

    before = len(row[3] or "")
    cur.execute(
        "UPDATE malayalam_about_translator SET bio = ?, email = ?, mobile = ? WHERE id = ?",
        (bio, EMAIL, ADDRESS, row[0]),
    )
    conn.commit()
    conn.close()
    paras = len([p for p in bio.split("\n") if p.strip()])
    print(
        f"{db_path}: updated id={row[0]} -- bio {before} -> {len(bio)} chars, "
        f"{paras} paragraphs; address moved into `mobile`"
    )


if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    bio = io.open(sys.argv[1], encoding="utf-8").read().strip()
    if not bio:
        raise SystemExit("ABORTED: bio file is empty")
    for path in sys.argv[2:]:
        apply(path, bio)
