# -*- coding: utf-8 -*-
"""One-time: insert missing Malayalam translation for Surah 4, verse 144."""
import sqlite3, os

DB = os.path.join(os.path.dirname(__file__), '..', 'assets', 'db',
                  'quran_asad_combined_nw.sqlite')

V144 = ("വിശ്വാസമാർജിച്ചവരേ, നിങ്ങൾ വിശ്വാസികളെ വെടിഞ്ഞ് "
        "സത്യനിഷേധികളെ സ്വന്തം സഖ്യകക്ഷികളായി സ്വീകരിക്കരുത്. ദൈവത്തിന് "
        "നിങ്ങൾക്കെതിരിൽ വ്യക്തമായ തെളിവുണ്ടാക്കിവെക്കാൻ നിങ്ങൾ "
        "ആഗ്രഹിക്കുന്നുവോ?")

conn = sqlite3.connect(DB)
cur = conn.cursor()

print("Before — surah 4 verses 142-146:")
for r in cur.execute(
        "SELECT id, verse_number FROM malayalam_verses "
        "WHERE surah_id = 4 AND verse_number BETWEEN 142 AND 146 "
        "ORDER BY verse_number"):
    print(r)

# Idempotent: clear any existing row for this verse first.
cur.execute(
    "DELETE FROM malayalam_verses WHERE surah_id = 4 AND verse_number = 144")

max_id = cur.execute("SELECT MAX(id) FROM malayalam_verses").fetchone()[0] or 0
cur.execute(
    "INSERT INTO malayalam_verses (id, surah_id, verse_number, malayalam_translation) "
    "VALUES (?, 4, 144, ?)", (max_id + 1, V144))

conn.commit()

print("After — surah 4 verses 142-146:")
for r in cur.execute(
        "SELECT id, verse_number, substr(malayalam_translation,1,40) "
        "FROM malayalam_verses WHERE surah_id = 4 AND verse_number BETWEEN 142 AND 146 "
        "ORDER BY verse_number"):
    print(r)
conn.close()
