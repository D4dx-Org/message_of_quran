# -*- coding: utf-8 -*-
"""One-time: split combined Malayalam translations in Surah 10.

Currently verse 61 holds the merged text for verses 61 and 62, and verse 79
holds the merged text for verses 79 and 80. This updates verses 61 and 79 to
their own text and inserts the missing rows for 62 and 80.
"""

import os
import sqlite3


DB = os.path.join(
    os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad_combined_nw.sqlite'
)

V61 = (
    "(നബിയേ,) നീ ഏതവസ്ഥയിലായിരുന്നാലും, ഖുര്‍ആനില്‍നിന്ന് എന്തു "
    "ഓതിക്കേള്‍പ്പിക്കുകയാണെങ്കിലും;[^507] ജനങ്ങളേ, നിങ്ങള്‍ എന്തു "
    "പ്രവര്‍ത്തിക്കുകയാണെങ്കിലും അവിടെയൊക്കെയും നാം ദൃക്‌സാക്ഷിയായി "
    "നിലകൊള്ളുന്നുണ്ട്.[^508] നിന്റെ നാഥന്റെ ദൃഷ്ടിയില്‍ പെടാതെയോ, "
    "സുവ്യക്തമായ പട്ടികയില്‍ രേഖപ്പെടുത്താതെയോ, ആകാശത്തോ ഭൂമിയിലോ "
    "ഒരു അണുതുല്യമായ വസ്തുവുമില്ല. അതിലും ചെറുതോ വലുതോ ആയ "
    "വസ്തുവുമില്ല."
)

V62 = (
    "ശ്രദ്ധിക്കുക: തീര്‍ച്ചയായും ദൈവത്തിന്റെ മിത്രങ്ങളാരോ[^509] "
    "അവരുടെ മേൽ യാതൊരു ഭയവുമില്ല. അവര്‍ ദുഃഖിക്കേണ്ടി വരികയുമില്ല"
)

V79 = (
    "ഫിര്‍ഔന്‍ പറഞ്ഞു: വിദഗ്ധരായ ആഭിചാരകന്മാരെയഖിലം നിങ്ങള്‍ എന്റെ "
    "അടുക്കല്‍ കൊണ്ട് വരൂ"
)

V80 = (
    "അങ്ങനെ ആഭിചാരകന്മാർ വന്നപ്പോള്‍ മൂസാ അവരോട് പറഞ്ഞു: “നിങ്ങള്‍ക്ക് "
    "എറിയാനുള്ളത് എറിയുക.”"
)


def print_rows(cur, label):
    print(label)
    for row in cur.execute(
        "SELECT id, verse_number, malayalam_translation "
        "FROM malayalam_verses "
        "WHERE surah_id = 10 AND verse_number IN (61, 62, 79, 80) "
        "ORDER BY verse_number"
    ):
        print(row)


conn = sqlite3.connect(DB)
cur = conn.cursor()

print_rows(cur, "Before - surah 10 verses 61, 62, 79, 80:")

cur.execute(
    "UPDATE malayalam_verses SET malayalam_translation = ? "
    "WHERE surah_id = 10 AND verse_number = 61",
    (V61,),
)
cur.execute(
    "UPDATE malayalam_verses SET malayalam_translation = ? "
    "WHERE surah_id = 10 AND verse_number = 79",
    (V79,),
)

cur.execute(
    "DELETE FROM malayalam_verses WHERE surah_id = 10 AND verse_number IN (62, 80)"
)

max_id = cur.execute("SELECT MAX(id) FROM malayalam_verses").fetchone()[0] or 0
cur.execute(
    "INSERT INTO malayalam_verses (id, surah_id, verse_number, malayalam_translation) "
    "VALUES (?, 10, 62, ?)",
    (max_id + 1, V62),
)
cur.execute(
    "INSERT INTO malayalam_verses (id, surah_id, verse_number, malayalam_translation) "
    "VALUES (?, 10, 80, ?)",
    (max_id + 2, V80),
)

conn.commit()

print_rows(cur, "After - surah 10 verses 61, 62, 79, 80:")
conn.close()