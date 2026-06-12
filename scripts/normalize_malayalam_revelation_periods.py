"""
normalize_malayalam_revelation_periods.py

One-time script to sync Malayalam revelation labels from the authoritative
English `surahs.period` field in the combined Quran DB.

Run from the repo root (the_message_of_the_quran/):
    python scripts/normalize_malayalam_revelation_periods.py
"""

import os
import shutil
import sqlite3
import sys

DB_PATH = os.path.join("assets", "db", "quran_asad_combined_nw.sqlite")
CANONICAL_LABELS = {
    "Makkah": "മക്കാ കാലഘട്ടം",
    "Madinah": "മദീനാ കാലഘട്ടം",
    "Period Uncertain": "കാലഘട്ടം അവ്യക്തം",
}
SAMPLE_SURAHS = (1, 2, 3, 12, 22, 29, 36)


def _english_period_counts(cur):
    cur.execute(
        "SELECT period, COUNT(*) FROM surahs GROUP BY period ORDER BY period"
    )
    return cur.fetchall()


def _malayalam_period_counts(cur):
    cur.execute(
        """
        SELECT revelation_period, COUNT(*)
        FROM malayalam_surahs
        GROUP BY revelation_period
        ORDER BY COUNT(*) DESC, revelation_period
        """
    )
    return cur.fetchall()


def _sample_rows(cur):
    placeholders = ", ".join("?" for _ in SAMPLE_SURAHS)
    cur.execute(
        f"""
        SELECT s.number, s.period, m.revelation_period
        FROM surahs s
        JOIN malayalam_surahs m ON m.chapter_number = s.number
        WHERE s.number IN ({placeholders})
        ORDER BY s.number
        """,
        SAMPLE_SURAHS,
    )
    return cur.fetchall()


def _unknown_english_periods(cur):
    placeholders = ", ".join("?" for _ in CANONICAL_LABELS)
    cur.execute(
        f"SELECT DISTINCT period FROM surahs WHERE period NOT IN ({placeholders}) ORDER BY period",
        tuple(CANONICAL_LABELS),
    )
    return [row[0] for row in cur.fetchall()]


def _unexpected_malayalam_labels(cur):
    placeholders = ", ".join("?" for _ in CANONICAL_LABELS.values())
    cur.execute(
        f"""
        SELECT DISTINCT revelation_period
        FROM malayalam_surahs
        WHERE revelation_period NOT IN ({placeholders})
        ORDER BY revelation_period
        """,
        tuple(CANONICAL_LABELS.values()),
    )
    return [row[0] for row in cur.fetchall()]


def _checkpoint_database(conn):
    cur = conn.cursor()
    full_result = cur.execute("PRAGMA wal_checkpoint(FULL)").fetchone()
    truncate_result = cur.execute("PRAGMA wal_checkpoint(TRUNCATE)").fetchone()
    print(f"Checkpoint FULL: {full_result}")
    print(f"Checkpoint TRUNCATE: {truncate_result}")


def main():
    if not os.path.isfile(DB_PATH):
        print(f"ERROR: DB not found at {DB_PATH}")
        sys.exit(1)

    backup = DB_PATH + ".bak"
    shutil.copy2(DB_PATH, backup)
    print(f"Backed up {DB_PATH} -> {backup}")

    conn = sqlite3.connect(DB_PATH)
    try:
        cur = conn.cursor()

        print("English periods:")
        print(_english_period_counts(cur))
        print("\nMalayalam sample rows before:")
        for row in _sample_rows(cur):
            print(row)

        unknown_periods = _unknown_english_periods(cur)
        if unknown_periods:
            print(f"ERROR: unsupported English period values: {unknown_periods}")
            sys.exit(1)

        updated_rows = 0
        for english_period, malayalam_label in CANONICAL_LABELS.items():
            cur.execute(
                """
                UPDATE malayalam_surahs
                SET revelation_period = ?
                WHERE chapter_number IN (
                    SELECT number FROM surahs WHERE period = ?
                )
                """,
                (malayalam_label, english_period),
            )
            updated_rows += cur.rowcount

        conn.commit()

        print(f"\nUpdated rows: {updated_rows}")
        print("\nMalayalam period counts after:")
        print(_malayalam_period_counts(cur))
        print("\nMalayalam sample rows after:")
        for row in _sample_rows(cur):
            print(row)

        unexpected_labels = _unexpected_malayalam_labels(cur)
        if unexpected_labels:
            print(f"ERROR: unexpected Malayalam labels remain: {unexpected_labels}")
            sys.exit(1)

        _checkpoint_database(conn)
        print("Done.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()