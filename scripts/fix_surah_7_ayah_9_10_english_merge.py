"""
fix_surah_7_ayah_9_10_english_merge.py

One-time script to split the merged English Asad translation for
Surah 7, ayahs 9 and 10 in quran_asad.sqlite.

Run from the repo root (the_message_of_the_quran/):
    python scripts/fix_surah_7_ayah_9_10_english_merge.py
"""

import os
import shutil
import sqlite3
import sys


ASAD_DB = os.path.join("assets", "db", "quran_asad.sqlite")
SURAH_NUMBER = 7
AYAH_9 = 9
AYAH_10 = 10
MERGED_TEXT = (
    "whereas those whose weight is light in the balance - it is they who "
    "will have squandered their own selves by their wilful rejection of Our "
    "messages! YEA, INDEED, [O men,] We have given you a [bountiful] place "
    "on earth, and appointed thereon means of livelihood for you: [yet] how "
    "seldom are you grateful!"
)
AYAH_9_TEXT = (
    "whereas those whose weight is light in the balance - it is they who "
    "will have squandered their own selves by their wilful rejection of Our "
    "messages!"
)
AYAH_10_TEXT = (
    "YEA, INDEED, [O men,] We have given you a [bountiful] place on earth, "
    "and appointed thereon means of livelihood for you: [yet] how seldom "
    "are you grateful!"
)


def _checkpoint_database(conn):
    cur = conn.cursor()
    full_result = cur.execute("PRAGMA wal_checkpoint(FULL)").fetchone()
    truncate_result = cur.execute("PRAGMA wal_checkpoint(TRUNCATE)").fetchone()
    print(f"Checkpoint FULL: {full_result}")
    print(f"Checkpoint TRUNCATE: {truncate_result}")


def _fetch_verse(cur, ayah_number):
    rows = cur.execute(
        "SELECT id, text FROM verses WHERE surah_number = ? AND verse_number = ?",
        (SURAH_NUMBER, ayah_number),
    ).fetchall()
    if len(rows) > 1:
        raise RuntimeError(
            f"Expected at most one row for {SURAH_NUMBER}:{ayah_number}, found {len(rows)}"
        )
    return rows[0] if rows else None


def _print_state(cur, label):
    rows = cur.execute(
        "SELECT id, verse_number, text FROM verses "
        "WHERE surah_number = ? AND verse_number IN (?, ?) "
        "ORDER BY verse_number ASC",
        (SURAH_NUMBER, AYAH_9, AYAH_10),
    ).fetchall()
    print(label)
    for row in rows:
        print(f"  id={row[0]} verse={row[1]} text={row[2]!r}")
    if not rows:
        print("  <no rows>")


def _apply_fix(cur):
    ayah_9_row = _fetch_verse(cur, AYAH_9)
    ayah_10_row = _fetch_verse(cur, AYAH_10)

    if ayah_9_row is None:
        raise RuntimeError(f"Missing required row for {SURAH_NUMBER}:{AYAH_9}")

    ayah_9_id, ayah_9_text = ayah_9_row
    ayah_10_id = ayah_10_row[0] if ayah_10_row else None
    ayah_10_text = ayah_10_row[1] if ayah_10_row else None

    already_fixed = ayah_9_text == AYAH_9_TEXT and ayah_10_text == AYAH_10_TEXT
    if already_fixed:
        print("No changes needed: Surah 7 ayahs 9 and 10 are already split.")
        return False

    if ayah_9_text not in {MERGED_TEXT, AYAH_9_TEXT}:
        raise RuntimeError(
            "Unexpected Surah 7:9 text. Aborting to avoid overwriting unknown data."
        )

    if ayah_10_text not in {None, "", AYAH_10_TEXT}:
        raise RuntimeError(
            "Unexpected Surah 7:10 text. Aborting to avoid overwriting unknown data."
        )

    if ayah_9_text != AYAH_9_TEXT:
        cur.execute(
            "UPDATE verses SET text = ? WHERE id = ?",
            (AYAH_9_TEXT, ayah_9_id),
        )

    if ayah_10_id is None:
        cur.execute(
            "INSERT INTO verses (surah_number, verse_number, text) VALUES (?, ?, ?)",
            (SURAH_NUMBER, AYAH_10, AYAH_10_TEXT),
        )
    elif ayah_10_text != AYAH_10_TEXT:
        cur.execute(
            "UPDATE verses SET text = ? WHERE id = ?",
            (AYAH_10_TEXT, ayah_10_id),
        )

    return True


def main():
    if not os.path.isfile(ASAD_DB):
        print(f"ERROR: DB not found at {ASAD_DB}")
        sys.exit(1)

    backup = ASAD_DB + ".bak"
    temp_db = ASAD_DB + ".tmp"
    patched_db = ASAD_DB + ".patched"
    shutil.copy2(ASAD_DB, temp_db)
    print(f"Working copy {ASAD_DB} -> {temp_db}")

    conn = sqlite3.connect(temp_db)
    replace_succeeded = False
    try:
        cur = conn.cursor()
        _print_state(cur, "Before:")
        changed = _apply_fix(cur)
        if changed:
            shutil.copy2(ASAD_DB, backup)
            print(f"Backed up {ASAD_DB} -> {backup}")
            conn.commit()
            _checkpoint_database(conn)
        _print_state(cur, "After:")
        if changed:
            conn.close()
            conn = None
            try:
                os.replace(temp_db, ASAD_DB)
                replace_succeeded = True
                if os.path.exists(patched_db):
                    os.remove(patched_db)
            except PermissionError as exc:
                shutil.copy2(temp_db, patched_db)
                raise RuntimeError(
                    "Could not replace assets/db/quran_asad.sqlite because another "
                    "app still has it open. Close DB Browser for SQLite (or any "
                    "other app using the file) and rerun this script. A patched copy "
                    f"was saved to {patched_db}."
                ) from exc
            print("Done.")
    finally:
        if conn is not None:
            conn.close()
        if os.path.exists(temp_db):
            os.remove(temp_db)


if __name__ == "__main__":
    main()