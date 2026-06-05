# -*- coding: utf-8 -*-
"""One-time: insert missing Malayalam translation for Surah 3, verse 27."""
import sqlite3, os

DB = os.path.join(os.path.dirname(__file__), '..', 'assets', 'db',
                  'quran_asad_combined_nw.sqlite')

V27 = ("പകലിനെ കുറച്ചുകൊണ്ട് നീ രാവിന് നീളം കൂട്ടുന്നു. രാവിനെ "
       "കുറച്ചുകൊണ്ട് നീ പകലിന് നീളം കൂട്ടുന്നു. ജീവനില്ലാത്തതിൽ നിന്ന് "
       "ജീവനുള്ളതിനെ പുറത്ത് വരുത്തുന്നു. ജീവനുള്ളതിൽ നിന്ന് "
       "നിർജീവമായതിനെയു‌ം. നീ ഇച്ഛിക്കുന്നവർക്ക് അളവറ്റ വിഭവങ്ങൾ "
       "നൽകുന്നു.")

conn = sqlite3.connect(DB)
cur = conn.cursor()

print("Before — surah 3 verses 25-29:")
for r in cur.execute(
        "SELECT id, verse_number FROM malayalam_verses "
        "WHERE surah_id = 3 AND verse_number BETWEEN 25 AND 29 "
        "ORDER BY verse_number"):
    print(r)

# Idempotent: clear any existing row for this verse first.
cur.execute(
    "DELETE FROM malayalam_verses WHERE surah_id = 3 AND verse_number = 27")

max_id = cur.execute("SELECT MAX(id) FROM malayalam_verses").fetchone()[0] or 0
cur.execute(
    "INSERT INTO malayalam_verses (id, surah_id, verse_number, malayalam_translation) "
    "VALUES (?, 3, 27, ?)", (max_id + 1, V27))

conn.commit()

print("After — surah 3 verses 25-29:")
for r in cur.execute(
        "SELECT id, verse_number, substr(malayalam_translation,1,40) "
        "FROM malayalam_verses WHERE surah_id = 3 AND verse_number BETWEEN 25 AND 29 "
        "ORDER BY verse_number"):
    print(r)
conn.close()
