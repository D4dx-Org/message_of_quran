# -*- coding: utf-8 -*-
"""One-time: split Surah 2 local interpretation 197 (raw footnote 206) into paragraphs."""

import os
import sqlite3


DB = os.path.join(
    os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad_combined_nw.sqlite'
)

SPLIT_TARGET = (
    'ദൈവികമായ മാർഗദർശനം അത്യന്താപേക്ഷിതമായ ഘട്ടമായിരുന്നു അത്. '
    '(ഇവിടെ ശ്രദ്ധേയമായ ഒരു കാര്യം'
)
SPLIT_REPLACEMENT = (
    'ദൈവികമായ മാർഗദർശനം അത്യന്താപേക്ഷിതമായ ഘട്ടമായിരുന്നു അത്.\n\n'
    'ഇവിടെ ശ്രദ്ധേയമായ ഒരു കാര്യം'
)


def print_rows(cur, label):
    print(label)
    for row in cur.execute(
        'SELECT id, footnote_number, content FROM malayalam_footnotes '
        'WHERE footnote_number = 206 ORDER BY id'
    ):
        print(row)


conn = sqlite3.connect(DB)
cur = conn.cursor()

print_rows(cur, 'Before - raw footnote 206:')

row = cur.execute(
    'SELECT id, content FROM malayalam_footnotes '
    'WHERE footnote_number = 206 ORDER BY id ASC LIMIT 1'
).fetchone()

if row is None:
    raise RuntimeError('Could not find raw Malayalam footnote 206')

row_id, content = row
content = content or ''
updated = content.replace(SPLIT_TARGET, SPLIT_REPLACEMENT, 1)

if updated == content:
    raise RuntimeError('Split target for raw Malayalam footnote 206 was not found')

cur.execute(
    'UPDATE malayalam_footnotes SET content = ? WHERE id = ?',
    (updated, row_id),
)

conn.commit()

print_rows(cur, 'After - raw footnote 206:')
conn.close()