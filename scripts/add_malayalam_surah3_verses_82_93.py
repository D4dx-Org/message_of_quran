# -*- coding: utf-8 -*-
"""One-time: insert missing Malayalam translations for Surah 3, verses 82 and 93."""
import os
import sqlite3

DB = os.path.join(
    os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad_combined_nw.sqlite'
)

V82 = (
    "അതിന് ശേഷം ആരെങ്കിലു\u200cം (പ്രതിജ്ഞയിൽ നിന്ന്) പിന്തിരിയുകയാണെങ്കിൽ "
    "അവർ തന്നെയാകുന്നു പാപികൾ."
)

V93 = (
    "തോറ അവതരിപ്പിക്കപ്പെടുന്നതിന് മുമ്പ് ഇസ്രായീൽ (യാക്കോബ്) തന്റെ മേൽ സ്വയം "
    "നിഷിദ്ധമാക്കിയതൊഴികെ എല്ലാ ഭക്ഷ്യവിഭവങ്ങളും ഇസ്രായീൽ സന്തതികൾക്ക് "
    "അനുവദനീയമായിരുന്നു[^360]. നിങ്ങൾ സത്യവാന്മാരാണെങ്കിൽ തോറ കൊണ്ടുവന്നു "
    "അതൊന്ന് വായിക്കുക."
)

conn = sqlite3.connect(DB)
cur = conn.cursor()

print("Before — surah 3 verses 81-94:")
for row in cur.execute(
    "SELECT id, verse_number, substr(malayalam_translation, 1, 80) "
    "FROM malayalam_verses WHERE surah_id = 3 AND verse_number BETWEEN 81 AND 94 "
    "ORDER BY verse_number"
):
    print(row)

# Idempotent: clear any existing rows for these verses first.
cur.execute(
    "DELETE FROM malayalam_verses WHERE surah_id = 3 AND verse_number IN (82, 93)"
)

max_id = cur.execute("SELECT MAX(id) FROM malayalam_verses").fetchone()[0] or 0
cur.execute(
    "INSERT INTO malayalam_verses (id, surah_id, verse_number, malayalam_translation) "
    "VALUES (?, 3, 82, ?)",
    (max_id + 1, V82),
)
cur.execute(
    "INSERT INTO malayalam_verses (id, surah_id, verse_number, malayalam_translation) "
    "VALUES (?, 3, 93, ?)",
    (max_id + 2, V93),
)

conn.commit()

print("After — surah 3 verses 81-94:")
for row in cur.execute(
    "SELECT id, verse_number, substr(malayalam_translation, 1, 80) "
    "FROM malayalam_verses WHERE surah_id = 3 AND verse_number BETWEEN 81 AND 94 "
    "ORDER BY verse_number"
):
    print(row)

print("Footnote lookup check for verse 93 marker:")
for row in cur.execute(
    "SELECT id, footnote_number, substr(content, 1, 80) "
    "FROM malayalam_footnotes WHERE footnote_number = 360 ORDER BY id ASC LIMIT 1"
):
    print(row)

conn.close()