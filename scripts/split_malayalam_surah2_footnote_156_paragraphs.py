# -*- coding: utf-8 -*-
"""One-time: split Surah 2 local interpretation 147 (raw footnote 156) into paragraphs."""

import os
import sqlite3


DB = os.path.join(
    os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad_combined_nw.sqlite'
)

SPLIT_TARGET = 'പ്രതികാരമല്ല അത്. ഖുർആൻ കൊലപാതക കേസിനെ'
SPLIT_REPLACEMENT = 'പ്രതികാരമല്ല അത്.\n\nഖുർആൻ കൊലപാതക കേസിനെ'


def print_rows(cur, label):
    print(label)
    for row in cur.execute(
        'SELECT id, footnote_number, content FROM malayalam_footnotes '
        'WHERE footnote_number = 156 ORDER BY id'
    ):
        print(row)


conn = sqlite3.connect(DB)
cur = conn.cursor()

print_rows(cur, 'Before - raw footnote 156:')

row = cur.execute(
    'SELECT id, content FROM malayalam_footnotes '
    'WHERE footnote_number = 156 ORDER BY id ASC LIMIT 1'
).fetchone()

if row is None:
    raise RuntimeError('Could not find raw Malayalam footnote 156')

row_id, content = row
content = content or ''
updated = content.replace(SPLIT_TARGET, SPLIT_REPLACEMENT, 1)

if updated == content:
    raise RuntimeError('Split target for raw Malayalam footnote 156 was not found')

cur.execute(
    'UPDATE malayalam_footnotes SET content = ? WHERE id = ?',
    (updated, row_id),
)

conn.commit()

print_rows(cur, 'After - raw footnote 156:')
conn.close()