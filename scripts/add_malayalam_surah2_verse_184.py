# -*- coding: utf-8 -*-
"""One-time: insert missing Malayalam translation for Surah 2, verse 184."""
import sqlite3, os

DB = os.path.join(os.path.dirname(__file__), '..', 'assets', 'db',
                  'quran_asad_combined_nw.sqlite')

V184 = ("എണ്ണപ്പെട്ട ഏതാനു‌ം ദിവസങ്ങളിൽ മാത്രം വ്രതമനുഷ്ഠിക്കുക. "
        "നിങ്ങളിലാരെങ്കിലു‌ം രോഗിയാവുകയോ യാത്രയിലാവുകയോ ചെയ്താൽ മറ്റു "
        "ദിവസങ്ങളിൽ നിന്ന് അത്രയു‌ം എണ്ണം (അനുഷ്ഠിക്കേണ്ടതാണ്.) "
        "(അത്തരം സാഹചര്യങ്ങളിൽ) ഒരു പാവപ്പെട്ടവന്നുള്ള ഭക്ഷണം "
        "പ്രായശ്ചിത്തമായി നൽകൽ കഴിവുള്ളവർക്ക് ബാധ്യതയാണ് . എന്നാൽ "
        "ആരെങ്കിലു‌ം സ്വയം സന്നദ്ധനായി കൂടുതൽ ചെയ്താൽ അതവന്ന് "
        "ഉത്തമമാകുന്നു. നിങ്ങൾ കാര്യം ഗ്രഹിക്കുന്നവരാണെങ്കിൽ "
        "വ്രതമനുഷ്ഠിക്കുന്നതാണ് നിങ്ങൾക്ക് കൂടുതൽ ഉത്തമം.")

conn = sqlite3.connect(DB)
cur = conn.cursor()

print("Before — surah 2 verses 182-186:")
for r in cur.execute(
        "SELECT id, verse_number FROM malayalam_verses "
        "WHERE surah_id = 2 AND verse_number BETWEEN 182 AND 186 "
        "ORDER BY verse_number"):
    print(r)

# Idempotent: clear any existing row for this verse first.
cur.execute(
    "DELETE FROM malayalam_verses WHERE surah_id = 2 AND verse_number = 184")

max_id = cur.execute("SELECT MAX(id) FROM malayalam_verses").fetchone()[0] or 0
cur.execute(
    "INSERT INTO malayalam_verses (id, surah_id, verse_number, malayalam_translation) "
    "VALUES (?, 2, 184, ?)", (max_id + 1, V184))

conn.commit()

print("After — surah 2 verses 182-186:")
for r in cur.execute(
        "SELECT id, verse_number, substr(malayalam_translation,1,40) "
        "FROM malayalam_verses WHERE surah_id = 2 AND verse_number BETWEEN 182 AND 186 "
        "ORDER BY verse_number"):
    print(r)
conn.close()
