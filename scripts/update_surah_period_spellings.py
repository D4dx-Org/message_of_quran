"""
update_surah_period_spellings.py

One-time script to normalize quran_asad surah period spellings.

Run from the repo root (the_message_of_the_quran/):
    python scripts/update_surah_period_spellings.py
"""

import os
import shutil
import sqlite3
import sys

ASAD_DB = os.path.join("assets", "db", "quran_asad.sqlite")
REPLACEMENTS = {
    "Mecca": "Makkah",
    "Medina": "Madinah",
}


def _period_counts(cur):
    cur.execute(
        "SELECT period, COUNT(*) FROM surahs GROUP BY period ORDER BY period"
    )
    return cur.fetchall()


def _checkpoint_database(conn):
    cur = conn.cursor()
    full_result = cur.execute("PRAGMA wal_checkpoint(FULL)").fetchone()
    truncate_result = cur.execute("PRAGMA wal_checkpoint(TRUNCATE)").fetchone()
    print(f"Checkpoint FULL: {full_result}")
    print(f"Checkpoint TRUNCATE: {truncate_result}")


def main():
    if not os.path.isfile(ASAD_DB):
        print(f"ERROR: DB not found at {ASAD_DB}")
        sys.exit(1)

    backup = ASAD_DB + ".bak"
    shutil.copy2(ASAD_DB, backup)
    print(f"Backed up {ASAD_DB} -> {backup}")

    conn = sqlite3.connect(ASAD_DB)
    try:
        cur = conn.cursor()
        before = _period_counts(cur)
        print(f"Before: {before}")

        updated_rows = 0
        for old_value, new_value in REPLACEMENTS.items():
            cur.execute(
                "UPDATE surahs SET period = ? WHERE period = ?",
                (new_value, old_value),
            )
            updated_rows += cur.rowcount

        conn.commit()

        after = _period_counts(cur)
        print(f"Updated rows: {updated_rows}")
        print(f"After: {after}")

        remaining_old_values = [
            period for period, _count in after if period in REPLACEMENTS
        ]
        if remaining_old_values:
            print(f"ERROR: old values still present: {remaining_old_values}")
            sys.exit(1)

        _checkpoint_database(conn)

        print("Done.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()