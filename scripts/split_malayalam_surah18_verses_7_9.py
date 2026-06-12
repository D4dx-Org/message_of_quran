# -*- coding: utf-8 -*-
"""One-time: split combined Malayalam translation of Surah 18 verses 7-9.

Currently verse 7 holds the merged text for verses 7, 8 and 9; verses 8 and 9
have no rows. This updates verse 7 to its own text and inserts 8 and 9.
"""

import os
import sqlite3


DB = os.path.join(
    os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad_combined_nw.sqlite'
)

V7 = (
    "ഭൂമിക്ക് മുകളിലുള്ള എല്ലാ അലങ്കാരങ്ങളെയും മനുഷ്യരെ പരീക്ഷിക്കാനുള്ള ഒരു ഉപാധിയായി[^1330] "
    "നാം നിശ്ചയിച്ചിരിക്കുന്നു. മനുഷ്യരില്‍ ഏറ്റവും നല്ല സൽകർമ്മചാരികൾ ആരെന്ന് പരീക്ഷിക്കാന്‍വേണ്ടി."
)

V8 = (
    "തീർച്ചയായും (വൈകാതെ) ഭൂമിക്കു മുകളിൽ ഉള്ളതിനെ എല്ലാം നാം തരിശായ "
    "പൊടിപടലങ്ങളായി മാറ്റും! (ഇഹലോകജീവിതം ഒരു പരീക്ഷണമാകയാൽ)[^1331]"
)

V9 = (
    "ഗുഹാവാസികളും(ഗുണപാഠകഥയും) വേദഗ്രന്ഥങ്ങളും (അവയോടുള്ള അവരുടെ ഭക്തി "
    "താൽപര്യവും) നമ്മുടെ (മറ്റു) ഏതു സന്ദേശങ്ങളെക്കാളും ഏറെ അദ്ഭുതാവഹമായി "
    "നീ കരുതുന്നുവോ?[^1332]"
)


def print_rows(cur, label):
    print(label)
    for row in cur.execute(
        "SELECT id, verse_number, malayalam_translation "
        "FROM malayalam_verses "
        "WHERE surah_id = 18 AND verse_number BETWEEN 7 AND 9 "
        "ORDER BY verse_number"
    ):
        print(row)


conn = sqlite3.connect(DB)
cur = conn.cursor()

print_rows(cur, "Before - surah 18 verses 7-9:")

cur.execute(
    "UPDATE malayalam_verses SET malayalam_translation = ? "
    "WHERE surah_id = 18 AND verse_number = 7",
    (V7,),
)

cur.execute(
    "DELETE FROM malayalam_verses WHERE surah_id = 18 AND verse_number IN (8, 9)"
)

max_id = cur.execute("SELECT MAX(id) FROM malayalam_verses").fetchone()[0] or 0
cur.execute(
    "INSERT INTO malayalam_verses (id, surah_id, verse_number, malayalam_translation) "
    "VALUES (?, 18, 8, ?)",
    (max_id + 1, V8),
)
cur.execute(
    "INSERT INTO malayalam_verses (id, surah_id, verse_number, malayalam_translation) "
    "VALUES (?, 18, 9, ?)",
    (max_id + 2, V9),
)

conn.commit()

print_rows(cur, "After - surah 18 verses 7-9:")
conn.close()