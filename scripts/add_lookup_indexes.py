"""
add_lookup_indexes.py

Adds the indexes the reading screens depend on.

Opening any surah runs a lookup per table. `verses` and `footnotes` already
had indexes from their primary keys, but `quranayas` (the Arabic text) and
`malayalam_verses` had none, so both were full scans of ~6,200 rows every time
a surah was opened. Locally that is 473ms across the 114 surahs versus 29ms
with the indexes in place.

Idempotent: CREATE INDEX IF NOT EXISTS, then ANALYZE so the planner has stats.

    python scripts/add_lookup_indexes.py <sqlite> [<sqlite> ...]
"""
import os
import sqlite3
import sys

INDEXES = [
    ('idx_quranayas_sura_aya', 'quranayas(suraid, ayaid)'),
    ('idx_ml_verses_surah_verse', 'malayalam_verses(surah_id, verse_number)'),
    ('idx_ml_footnotes_number', 'malayalam_footnotes(footnote_number)'),
]


def apply(db_path):
    before = os.path.getsize(db_path)
    conn = sqlite3.connect(db_path)
    made = []
    for name, target in INDEXES:
        table = target.split('(')[0]
        exists = conn.execute(
            "SELECT 1 FROM sqlite_master WHERE type='table' AND name=?", (table,)
        ).fetchone()
        if not exists:
            print(f'  skipped {name}: no {table} table')
            continue
        had = conn.execute(
            "SELECT 1 FROM sqlite_master WHERE type='index' AND name=?", (name,)
        ).fetchone()
        conn.execute(f'CREATE INDEX IF NOT EXISTS {name} ON {target}')
        if not had:
            made.append(name)
    conn.execute('ANALYZE')
    conn.commit()
    conn.close()
    after = os.path.getsize(db_path)
    print(
        f'{db_path}: {len(made)} index(es) created {made} '
        f'({before // 1024 // 1024}MB -> {after // 1024 // 1024}MB)'
    )


if __name__ == '__main__':
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    for db in sys.argv[1:]:
        apply(db)
