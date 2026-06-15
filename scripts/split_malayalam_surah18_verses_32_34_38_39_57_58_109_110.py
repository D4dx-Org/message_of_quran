# -*- coding: utf-8 -*-
"""One-time: split merged Malayalam translations in Surah 18.

This fixes four merged ranges in the bundled combined DB:
- verse 32 currently contains verses 32, 33 and 34
- verse 38 currently contains verses 38 and 39
- verse 57 currently contains verses 57 and 58
- verse 109 currently contains verses 109 and 110

The split uses the exact text already stored in the DB as source of truth and
removes only the inline verse-number labels that were causing merged rendering.
"""

import os
import sqlite3


DB = os.path.join(
    os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad_combined_nw.sqlite'
)


def _fetch_text(cur, verse_number):
    row = cur.execute(
        'SELECT malayalam_translation FROM malayalam_verses '
        'WHERE surah_id = 18 AND verse_number = ?',
        (verse_number,),
    ).fetchone()
    return row[0] if row else None


def _split_once(text, marker):
    if text is None or marker not in text:
        return None, None
    left, right = text.split(marker, 1)
    return left.strip(), right.strip()


def _derive_v32_v34(cur):
    current32 = _fetch_text(cur, 32)
    if current32 and '\n33-34. ' in current32:
        v32, tail = _split_once(current32, '\n33-34. ')
        v33, v34 = _split_once(tail, 'തന്നിമിത്തം (ആ വ്യക്തിക്ക്)')
        if v33 is None or v34 is None:
            raise RuntimeError('Could not split Surah 18 verse 32 merged text into 33 and 34')
        return v32, v33, f'തന്നിമിത്തം (ആ വ്യക്തിക്ക്) {v34.lstrip()}'

    v32 = current32
    v33 = _fetch_text(cur, 33)
    v34 = _fetch_text(cur, 34)
    if not v32 or not v33 or not v34:
        raise RuntimeError('Missing Surah 18 verses 32/33/34 and merged source is unavailable')
    return v32.strip(), v33.strip(), v34.strip()


def _derive_v38_v39(cur):
    current38 = _fetch_text(cur, 38)
    if current38 and '\n18 :39. ' in current38:
        v38, v39 = _split_once(current38, '\n18 :39. ')
        if v38 is None or v39 is None:
            raise RuntimeError('Could not split Surah 18 verse 38 merged text into 39')
        return v38, v39

    v39 = _fetch_text(cur, 39)
    if not current38 or not v39:
        raise RuntimeError('Missing Surah 18 verses 38/39 and merged source is unavailable')
    return current38.strip(), v39.strip()


def _derive_v57_v58(cur):
    current57 = _fetch_text(cur, 57)
    if current57 and '\n(58) ' in current57:
        v57, v58 = _split_once(current57, '\n(58) ')
        if v57 is None or v58 is None:
            raise RuntimeError('Could not split Surah 18 verse 57 merged text into 58')
        return v57, v58

    v58 = _fetch_text(cur, 58)
    if not current57 or not v58:
        raise RuntimeError('Missing Surah 18 verses 57/58 and merged source is unavailable')
    return current57.strip(), v58.strip()


def _derive_v109_v110(cur):
    current109 = _fetch_text(cur, 109)
    if current109 and '\n18:110. ' in current109:
        v109, v110 = _split_once(current109, '\n18:110. ')
        if v109 is None or v110 is None:
            raise RuntimeError('Could not split Surah 18 verse 109 merged text into 110')
        return v109, v110

    v110 = _fetch_text(cur, 110)
    if not current109 or not v110:
        raise RuntimeError('Missing Surah 18 verses 109/110 and merged source is unavailable')
    return current109.strip(), v110.strip()


def print_rows(cur, label):
    print(label)
    for row in cur.execute(
        'SELECT id, verse_number, malayalam_translation '
        'FROM malayalam_verses '
        'WHERE surah_id = 18 AND verse_number IN (32, 33, 34, 38, 39, 57, 58, 109, 110) '
        'ORDER BY verse_number'
    ):
        print(row)


conn = sqlite3.connect(DB)
cur = conn.cursor()

print_rows(cur, 'Before - surah 18 target verses:')

v32, v33, v34 = _derive_v32_v34(cur)
v38, v39 = _derive_v38_v39(cur)
v57, v58 = _derive_v57_v58(cur)
v109, v110 = _derive_v109_v110(cur)

v34 = v34.replace(
    'തന്നിമിത്തം (ആ വ്യക്തിക്ക്)സമൃദ്ധമായി',
    'തന്നിമിത്തം (ആ വ്യക്തിക്ക്) സമൃദ്ധമായി',
    1,
)

cur.execute(
    'UPDATE malayalam_verses SET malayalam_translation = ? '
    'WHERE surah_id = 18 AND verse_number = 32',
    (v32,),
)
cur.execute(
    'UPDATE malayalam_verses SET malayalam_translation = ? '
    'WHERE surah_id = 18 AND verse_number = 38',
    (v38,),
)
cur.execute(
    'UPDATE malayalam_verses SET malayalam_translation = ? '
    'WHERE surah_id = 18 AND verse_number = 57',
    (v57,),
)
cur.execute(
    'UPDATE malayalam_verses SET malayalam_translation = ? '
    'WHERE surah_id = 18 AND verse_number = 109',
    (v109,),
)

cur.execute(
    'DELETE FROM malayalam_verses WHERE surah_id = 18 AND verse_number IN (33, 34, 39, 58, 110)'
)

max_id = cur.execute('SELECT MAX(id) FROM malayalam_verses').fetchone()[0] or 0
new_rows = [
    (max_id + 1, 33, v33),
    (max_id + 2, 34, v34),
    (max_id + 3, 39, v39),
    (max_id + 4, 58, v58),
    (max_id + 5, 110, v110),
]
cur.executemany(
    'INSERT INTO malayalam_verses (id, surah_id, verse_number, malayalam_translation) '
    'VALUES (?, 18, ?, ?)',
    new_rows,
)

conn.commit()

print_rows(cur, 'After - surah 18 target verses:')
conn.close()