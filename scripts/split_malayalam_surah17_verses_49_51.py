# -*- coding: utf-8 -*-
"""One-time: split combined Malayalam translation of Surah 17 verses 49-51.

Currently verse 49 holds the merged text for 49, 50 and 51; verses 50 and 51
have no rows. This updates verse 49 to its own text and inserts 50 and 51.
"""
import sqlite3, os

DB = os.path.join(os.path.dirname(__file__), '..', 'assets', 'db',
                  'quran_asad_combined_nw.sqlite')

V49 = ("(എന്നിട്ടും) അവര്‍ ചോദിക്കും, ഞങ്ങള്‍ കേവലമായ അസ്ഥികളും "
       "മണ്ണുമായിത്തീര്‍ന്നാൽ, മരണത്തില്‍ നിന്നും പുതിയ സൃഷ്ടിയായി "
       "പുനര്‍ജീവിപ്പിക്കപ്പെടും എന്നാണോ?")

V50 = "പറയുക: നിങ്ങള്‍ കല്ലായാലും ഇരുമ്പായാലും ."

V51 = ("(ജീവന്റെ തുടിപ്പില്‍‍ നിന്നും) ഏറെയകലത്തിലുള്ള എത്ര കഠിനമായ "
       "വസ്തുവുമായിക്കൊള്ളട്ടെ[^1249], (നിങ്ങള്‍ മരണത്തില്‍ നിന്നും "
       "ഉയിര്‍ത്തെഴുന്നേല്‍പ്പിക്കപ്പെടും)! അപ്പോള്‍ അവര്‍ ചോദിക്കും: "
       "ആരാണ് ഞങ്ങളെ ജീവിതത്തിലേക്ക് തിരിച്ചുകൊണ്ട് വരിക? "
       "നിങ്ങളവരോട് പറയുക: നിങ്ങളെ ആദ്യം ജീവിതത്തിലേക്ക് "
       "കൊണ്ടുവന്നവനാരോ അവന്‍! അവര്‍ അപ്പോള്‍ നിങ്ങള്‍ നേരെ "
       "(അവിശ്വാസത്തോടെ) തലയിളക്കിക്കൊണ്ട് ചോദിക്കുകയും ചെയ്യും: "
       "എന്നാണിത് സംഭവിക്കുക? - അപ്പോള്‍ (പ്രവാചകരേ) നിങ്ങള്‍ പറയുക: "
       "അടുത്തു തന്നെ അത് സംഭവിച്ചേക്കാം!")

conn = sqlite3.connect(DB)
cur = conn.cursor()

print("Before — surah 17 verses 48-52:")
for r in cur.execute(
        "SELECT id, verse_number, substr(malayalam_translation,1,45) "
        "FROM malayalam_verses WHERE surah_id = 17 AND verse_number BETWEEN 48 AND 52 "
        "ORDER BY verse_number"):
    print(r)

# Verse 49: replace the merged text with just its own translation.
cur.execute(
    "UPDATE malayalam_verses SET malayalam_translation = ? "
    "WHERE surah_id = 17 AND verse_number = 49", (V49,))

# Verses 50 & 51: idempotent clear then insert new rows.
cur.execute(
    "DELETE FROM malayalam_verses WHERE surah_id = 17 AND verse_number IN (50, 51)")

max_id = cur.execute("SELECT MAX(id) FROM malayalam_verses").fetchone()[0] or 0
cur.execute(
    "INSERT INTO malayalam_verses (id, surah_id, verse_number, malayalam_translation) "
    "VALUES (?, 17, 50, ?)", (max_id + 1, V50))
cur.execute(
    "INSERT INTO malayalam_verses (id, surah_id, verse_number, malayalam_translation) "
    "VALUES (?, 17, 51, ?)", (max_id + 2, V51))

conn.commit()

print("After — surah 17 verses 48-52:")
for r in cur.execute(
        "SELECT id, verse_number, substr(malayalam_translation,1,45) "
        "FROM malayalam_verses WHERE surah_id = 17 AND verse_number BETWEEN 48 AND 52 "
        "ORDER BY verse_number"):
    print(r)
conn.close()
