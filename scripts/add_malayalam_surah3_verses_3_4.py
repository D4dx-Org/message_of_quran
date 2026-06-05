# -*- coding: utf-8 -*-
"""One-time: insert missing Malayalam translations for Surah 3, verses 3 and 4."""
import sqlite3, os

DB = os.path.join(os.path.dirname(__file__), '..', 'assets', 'db',
                  'quran_asad_combined_nw.sqlite')

V3 = ("അവൻ സത്യവുമായി ഈ വേദഗ്രന്ഥത്തെ പടിപടിയായി നിനക്ക് അവതരിപ്പിച്ചു "
      "തന്നിരിക്കുന്നു, (മുൻ വേദങ്ങളിൽ) ഇപ്പോഴു‌ം അവശേഷിക്കുന്നവയെ "
      "ശരിവെച്ചുകൊണ്ട്; അവനാണ് തോറയും സുവിശേഷവും അവതരിപ്പിച്ചത്.")

V4 = ("മനുഷ്യർക്ക് മാർഗദർശനത്തിനായി മുമ്പ് സത്യാസത്യവിവേചനത്തിനുള്ള "
      "പ്രമാണവു‌ം അവൻ അവതരിപ്പിച്ചിരിക്കുന്നു. തീർച്ചയായു‌ം "
      "ദിവ്യസന്ദേശങ്ങൾ നിഷേധിച്ചുകൊണ്ടേയിരിക്കുന്നവർക്ക് കഠിനമായ "
      "ശിക്ഷയാണുള്ളത്. ദൈവം സർവശക്തനു‌ം ദുഷ്ടരോട് പ്രതികാരം "
      "ചെയ്യുന്നവനുമാകുന്നു.")

conn = sqlite3.connect(DB)
cur = conn.cursor()

# Remove any pre-existing rows for these verses to keep the script idempotent.
cur.execute(
    "DELETE FROM malayalam_verses WHERE surah_id = 3 AND verse_number IN (3, 4)")

max_id = cur.execute("SELECT MAX(id) FROM malayalam_verses").fetchone()[0] or 0
cur.execute(
    "INSERT INTO malayalam_verses (id, surah_id, verse_number, malayalam_translation) "
    "VALUES (?, 3, 3, ?)", (max_id + 1, V3))
cur.execute(
    "INSERT INTO malayalam_verses (id, surah_id, verse_number, malayalam_translation) "
    "VALUES (?, 3, 4, ?)", (max_id + 2, V4))

conn.commit()

print("Inserted. Surah 3 verses 1-6 now:")
for r in cur.execute(
        "SELECT id, verse_number, substr(malayalam_translation,1,40) "
        "FROM malayalam_verses WHERE surah_id = 3 AND verse_number <= 6 "
        "ORDER BY verse_number"):
    print(r)
conn.close()
