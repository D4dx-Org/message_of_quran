"""One-off: insert the Surah 102 (At-Takathur) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 2, 4, 6, 7 -- 4 footnotes, matching
the 4 footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 102 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah102.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 102

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "At-Takathur",
    "malayalam_name": "അത്തകാസുർ",
    "english_translation": "The Greed for More and More",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "ഈ പ്രാരംഭ മക്കാ സൂറത്ത് ഖുർആനിലെ ഏറ്റവും "
        "ശക്തമായ പ്രവചന ഭാഗങ്ങളിൽ ഒന്നാണ്, ഇത് "
        "പൊതുവായി മനുഷ്യന്റെ അതിരുകളില്ലാത്ത "
        "ആർത്തിയിലേക്കും, കൂടുതൽ പ്രത്യേകമായി "
        "നമ്മുടെ സാങ്കേതിക യുഗത്തിലെ എല്ലാ മാനവ "
        "സമൂഹങ്ങളെയും കീഴടക്കിയിരിക്കുന്ന "
        "പ്രവണതകളിലേക്കും വെളിച്ചം വീശുന്നു."
    ),
}

VERSES = {
    1: "കൂടുതൽ കൂടുതൽ വേണമെന്നുള്ള ആർത്തി നിങ്ങളെ ബോധശൂന്യരാക്കിയിരിക്കുന്നു;",
    2: "നിങ്ങൾ കല്ലറകളിൽ എത്തുന്നതുവരെ.[^1]",
    3: "ഒരിക്കലുമല്ല, ഭാവിയിൽ നിങ്ങൾ മനസ്സിലാക്കിക്കൊള്ളും!",
    4: "വീണ്ടും ഉറപ്പിച്ചു പറയുന്നു:[^2] അല്ല, ഭാവിയിൽ നിങ്ങൾ അത് തിരിച്ചറിയുകതന്നെ ചെയ്യും!",
    5: "അല്ല, നിങ്ങള്‍ക്ക് സുദൃഢമായ ജ്ഞാനമുണ്ടായിരുന്നുവെങ്കില്‍ (നിങ്ങൾ ഇങ്ങനെ അശ്രദ്ധരാകുമായിരുന്നില്ല)!",
    6: "തീർച്ചയായും, നിങ്ങൾ ആ ജ്വലിക്കുന്ന നരകാഗ്നി കാണുകതന്നെ ചെയ്യും.[^3]",
    7: "പിന്നീട്, തികഞ്ഞ അനുഭവജ്ഞാനത്തോടെ നിങ്ങൾ അത് കണ്ടറിയുകതന്നെ ചെയ്യും.[^4]",
    8: "പിന്നീട്, അന്നാളില്‍ ദിവ്യാനുഗ്രഹങ്ങളെക്കുറിച്ച് (നിങ്ങൾ എന്തു ചെയ്തു എന്നതിനെക്കുറിച്ച്) നിങ്ങൾ തീർച്ചയായും ചോദ്യം ചെയ്യപ്പെടുകതന്നെ ചെയ്യും!",
}

FOOTNOTES = {
    1: (
        "തകാസുർ' എന്ന പദം \"കൂടുതൽ നേടാൻ "
        "ആർത്തിയോടെ കഠിനശ്രമം നടത്തുക\" എന്ന "
        "അർത്ഥം ഉൾക്കൊള്ളുന്നു; അത് ഭൗതികമോ "
        "അല്ലാത്തതോ, യഥാർത്ഥമോ മിഥ്യയോ ആയ "
        "നേട്ടങ്ങളാകട്ടെ. മുകളിലെ സന്ദർഭത്തിൽ "
        "ഇത് സൂചിപ്പിക്കുന്നത് കൂടുതൽ "
        "സുഖസൗകര്യങ്ങൾക്കും, കൂടുതൽ ഭൗതിക "
        "വസ്തുക്കൾക്കും, സഹജീവികളുടെ മേലോ "
        "പ്രകൃതിയുടെ മേലോ ഉള്ള വലിയ "
        "അധികാരത്തിനും, നിരന്തരമായ സാങ്കേതിക "
        "പുരോഗതിക്കും വേണ്ടിയുള്ള മനുഷ്യന്റെ "
        "അമിതാവേശത്തെയാണ്. മറ്റെല്ലാം "
        "ഒഴിവാക്കിക്കൊണ്ട് അത്തരം "
        "പരിശ്രമങ്ങളെ മാത്രം തീവ്രമായി "
        "പിന്തുടരുന്നത് മനുഷ്യനെ ആത്മീയ "
        "ഉൾക്കാഴ്ചകളിൽ നിന്നും, കേവലം "
        "ധാർമ്മിക മൂല്യങ്ങളെ അടിസ്ഥാനമാക്കിയുള്ള "
        "നിയന്ത്രണങ്ങളെയും വിലക്കുകളെയും "
        "സ്വീകരിക്കുന്നതിൽ നിന്നും "
        "തടയുന്നു — ഇതിന്റെ ഫലമായി "
        "വ്യക്തികൾക്ക് മാത്രമല്ല, വലിയ "
        "സമൂഹങ്ങൾക്ക് പോലും അവരുടെ ആന്തരിക "
        "സുസ്ഥിരതയും അങ്ങനെ സന്തോഷത്തിനുള്ള "
        "എല്ലാ അവസരങ്ങളും ക്രമേണ "
        "നഷ്ടപ്പെടുന്നു."
    ),
    2: "സൂറഃ 6, കുറിപ്പ് 31 കാണുക.",
    3: (
        "ചുരുക്കത്തിൽ, \"നിങ്ങൾ ഇപ്പോൾ "
        "ജീവിച്ചുകൊണ്ടിരിക്കുന്ന അവസ്ഥ\" — "
        "അതായത് അടിസ്ഥാനപരമായി തെറ്റായ "
        "ജീവിതരീതി കാരണം ഭൂമിയിൽ തന്നെ "
        "സൃഷ്ടിക്കപ്പെടുന്ന നരകം: "
        "മനുഷ്യന്റെ സ്വാഭാവിക പരിസ്ഥിതിയുടെ "
        "ക്രമാനുഗതമായ നാശത്തിലേക്കും, "
        "ആത്മീയവും മതപരവുമായ എല്ലാ "
        "ദിശാബോധങ്ങളുടെയും അവശിഷ്ടങ്ങൾ "
        "നഷ്ടപ്പെടാൻ പോകുന്ന ഈ "
        "കാലഘട്ടത്തിലെ മനുഷ്യരാശിക്ക് "
        "മേൽ, നിയന്ത്രണമില്ലാത്ത "
        "\"സാമ്പത്തിക വളർച്ചയുടെ\" "
        "അമിതമായ പിന്തുടരൽ അനിവാര്യമായും "
        "വരുത്തിവെക്കുന്ന — വാസ്തവത്തിൽ "
        "വരുത്തിവെച്ചിട്ടുള്ള — "
        "നിരാശയിലേക്കും അതൃപ്തിയിലേക്കും "
        "ആശയക്കുഴപ്പത്തിലേക്കുമുള്ള ഒരു "
        "സൂചനയാണിത്."
    ),
    4: (
        "അതായത് പരലോകത്ത് വെച്ച്, ഒരാൾ "
        "തന്റെ കഴിഞ്ഞകാല പ്രവൃത്തികളുടെ "
        "യഥാർത്ഥ സ്വഭാവത്തെക്കുറിച്ചും, "
        "ജീവിതമെന്ന അനുഗ്രഹം (അൻ-നഈം) "
        "തെറ്റായും വ്യർത്ഥമായും "
        "ഉപയോഗിച്ചതിലൂടെ മനുഷ്യൻ സ്വയം "
        "വരുത്തിവെക്കുന്ന ശിക്ഷയുടെ "
        "അനിവാര്യതയെക്കുറിച്ചുമുള്ള "
        "നേരിട്ടുള്ള, സംശയമില്ലാത്ത "
        "ഉൾക്കാഴ്ചയിലൂടെ."
    ),
}


def apply(db_path):
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    cur.execute("DELETE FROM malayalam_surahs WHERE chapter_number = ?", (CHAPTER,))
    cur.execute(
        "INSERT INTO malayalam_surahs "
        "(chapter_number, arabic_name, malayalam_name, english_translation, "
        "revelation_period, introduction) VALUES (?, ?, ?, ?, ?, ?)",
        (
            SURAH["chapter_number"], SURAH["arabic_name"],
            SURAH["malayalam_name"], SURAH["english_translation"],
            SURAH["revelation_period"], SURAH["introduction"],
        ),
    )

    columns = [row[1] for row in cur.execute("PRAGMA table_info(malayalam_footnotes)")]
    has_surah_number = "surah_number" in columns

    if has_surah_number:
        offset = 0
    else:
        row = cur.execute(
            "SELECT MAX(footnote_number) FROM malayalam_footnotes WHERE id != footnote_number"
        ).fetchone()
        offset = row[0] or 0

    def shift_markers(text):
        if offset == 0:
            return text
        return re.sub(
            r"\[\^(\d+)\]", lambda m: f"[^{int(m.group(1)) + offset}]", text
        )

    cur.execute("DELETE FROM malayalam_verses WHERE surah_id = ?", (CHAPTER,))
    for verse_number, text in VERSES.items():
        cur.execute(
            "INSERT INTO malayalam_verses (surah_id, verse_number, malayalam_translation) "
            "VALUES (?, ?, ?)",
            (CHAPTER, verse_number, shift_markers(text)),
        )

    if has_surah_number:
        cur.execute("DELETE FROM malayalam_footnotes WHERE surah_number = ?", (CHAPTER,))
        for footnote_number, content in FOOTNOTES.items():
            cur.execute(
                "INSERT INTO malayalam_footnotes (footnote_number, content, surah_number) "
                "VALUES (?, ?, ?)",
                (footnote_number, content, CHAPTER),
            )
    else:
        for footnote_number, content in FOOTNOTES.items():
            cur.execute(
                "INSERT INTO malayalam_footnotes (footnote_number, content) VALUES (?, ?)",
                (footnote_number + offset, content),
            )

    conn.commit()
    conn.close()
    print(
        f"Surah {CHAPTER}: inserted 1 surah row, {len(VERSES)} verses, "
        f"{len(FOOTNOTES)} footnotes into {db_path} "
        f"(surah_number column: {has_surah_number}, footnote offset: {offset})"
    )


if __name__ == "__main__":
    for path in sys.argv[1:]:
        apply(path)
