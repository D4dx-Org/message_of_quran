"""
migrate_thafheem_to_asad.py

One-time script to restructure Malayalam data within quran_asad.sqlite.

Merges surah_introduction into the ayah_id=1 row for each surah (not separate rows).
Detects current state and either does full migration or fixup.

Run from the repo root (the_message_of_the_quran/):
    python scripts/migrate_thafheem_to_asad.py
"""

import sqlite3
import os
import sys
import shutil
from collections import defaultdict

ASAD_DB = os.path.join("assets", "db", "quran_asad.sqlite")


def main():
    if not os.path.isfile(ASAD_DB):
        print(f"ERROR: DB not found at {ASAD_DB}")
        sys.exit(1)

    backup = ASAD_DB + ".bak"
    shutil.copy2(ASAD_DB, backup)
    print(f"Backed up {ASAD_DB} → {backup}")

    conn = sqlite3.connect(ASAD_DB)
    conn.row_factory = sqlite3.Row
    cur = conn.cursor()

    # Detect current state
    cur.execute("PRAGMA table_info(quranayas)")
    quranayas_cols = [row[1] for row in cur.fetchall()]

    if "AudioText" in quranayas_cols:
        print("Running FULL migration (AudioText found in quranayas)...")
        _full_migration(cur)
    else:
        print("quranayas already clean. Running surah_introduction fixup...")
        _fixup_surah_intro(cur)

    conn.commit()
    _verify(cur)
    conn.close()
    print(f"\nDone! Backup saved at: {backup}")


def _full_migration(cur):
    """Full migration: read old data, recreate tables, merge intro into ayah rows."""

    cur.execute("SELECT suraid, ayaid, AudioText, AudioIntrerptn FROM quranayas")
    ayah_rows = cur.fetchall()
    print(f"Read {len(ayah_rows)} rows from quranayas")

    cur.execute("SELECT preface_text, sura_id FROM malayalam_prefaces")
    preface_rows = cur.fetchall()
    print(f"Read {len(preface_rows)} rows from malayalam_prefaces")

    # Group preface texts by surah_id
    intros = defaultdict(list)
    for row in preface_rows:
        text = row["preface_text"] or ""
        if text.strip():
            intros[row["sura_id"]].append(text.strip())

    # Remove AudioText & AudioIntrerptn from quranayas
    cur.execute("""
        CREATE TABLE quranayas_clean (
            contiayano INTEGER, suraid INTEGER, ayaid INTEGER, AyaHText TEXT
        )
    """)
    cur.execute("INSERT INTO quranayas_clean SELECT contiayano, suraid, ayaid, AyaHText FROM quranayas")
    cur.execute("DROP TABLE quranayas")
    cur.execute("ALTER TABLE quranayas_clean RENAME TO quranayas")
    print("Removed AudioText & AudioIntrerptn columns from quranayas")

    # Create malayalam_dummy_datas table
    cur.execute("DROP TABLE IF EXISTS malayalam_dummy_datas")
    cur.execute("DROP TABLE IF EXISTS malayalam_prefaces")
    cur.execute("""
        CREATE TABLE malayalam_dummy_datas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            surah_id INTEGER NOT NULL,
            ayah_id INTEGER NOT NULL,
            malayalam_translation TEXT,
            malayalam_interpretation TEXT,
            surah_introduction TEXT
        )
    """)
    print("Created malayalam_dummy_datas table")

    # Insert per-ayah data WITH surah_introduction on ayah_id=1
    ayah_inserted = 0
    for row in ayah_rows:
        suraid, ayaid = row["suraid"], row["ayaid"]
        audio_text = row["AudioText"] or ""
        audio_interp = row["AudioIntrerptn"] or ""

        if audio_text.strip() or audio_interp.strip():
            surah_intro = None
            if ayaid == 1 and suraid in intros:
                surah_intro = "\n\n".join(intros[suraid])

            cur.execute(
                "INSERT INTO malayalam_dummy_datas (surah_id, ayah_id, malayalam_translation, malayalam_interpretation, surah_introduction) VALUES (?, ?, ?, ?, ?)",
                (suraid, ayaid, audio_text.strip() or None, audio_interp.strip() or None, surah_intro),
            )
            ayah_inserted += 1

    print(f"Inserted {ayah_inserted} ayah rows")
    print(f"Surah introductions merged into ayah_id=1 for {len(intros)} surahs")


def _fixup_surah_intro(cur):
    """Fix existing DB: merge standalone intro rows into ayah_id=1 rows."""

    cur.execute("SELECT surah_id, surah_introduction FROM malayalam_dummy_datas WHERE ayah_id IS NULL AND surah_introduction IS NOT NULL ORDER BY id")
    intro_rows = cur.fetchall()

    if not intro_rows:
        print("No standalone intro rows found. Nothing to fix.")
        return

    intros = defaultdict(list)
    for row in intro_rows:
        text = row["surah_introduction"] or ""
        if text.strip():
            intros[row["surah_id"]].append(text.strip())

    print(f"Found intros for {len(intros)} surahs ({len(intro_rows)} rows)")

    updated = 0
    for surah_id, texts in intros.items():
        combined = "\n\n".join(texts)
        cur.execute(
            "UPDATE malayalam_dummy_datas SET surah_introduction = ? WHERE surah_id = ? AND ayah_id = 1",
            (combined, surah_id),
        )
        if cur.rowcount > 0:
            updated += 1

    print(f"Updated {updated} ayah_id=1 rows with surah_introduction")

    cur.execute("DELETE FROM malayalam_dummy_datas WHERE ayah_id IS NULL")
    print(f"Deleted {cur.rowcount} standalone intro rows")


def _verify(cur):
    cur.execute("PRAGMA table_info(quranayas)")
    cols = [row[1] for row in cur.fetchall()]
    print(f"\nquranayas columns: {cols}")

    cur.execute("SELECT COUNT(*) FROM malayalam_dummy_datas")
    print(f"Total rows: {cur.fetchone()[0]}")

    cur.execute("SELECT COUNT(*) FROM malayalam_dummy_datas WHERE surah_introduction IS NOT NULL")
    print(f"Rows with surah_introduction: {cur.fetchone()[0]}")

    cur.execute("SELECT COUNT(*) FROM malayalam_dummy_datas WHERE ayah_id IS NULL")
    print(f"Standalone rows (should be 0): {cur.fetchone()[0]}")

    cur.execute("SELECT surah_id, ayah_id, substr(surah_introduction, 1, 60) FROM malayalam_dummy_datas WHERE surah_introduction IS NOT NULL LIMIT 3")
    print("\nSample rows with surah_introduction (should have ayah_id=1):")
    for r in cur.fetchall():
        print(f"  surah={r[0]}, ayah={r[1]}, intro={r[2]}...")


if __name__ == "__main__":
    main()
