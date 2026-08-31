"""One-off: insert the Surah 101 (Al-Qari'ah) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 1, 9, 11 -- 3 footnotes, matching the
3 footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 101 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah101.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 101

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Al-Qari'ah",
    "malayalam_name": "അൽ ഖാരിഅ",
    "english_translation": "The Sudden Calamity",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "ഒരു ആദ്യകാല മക്കാ സൂറത്ത്, മിക്കവാറും സൂറഃ "
        "95-ന് (അത്തീൻ) ശേഷം അവതീർണമായത്."
    ),
}

VERSES = {
    1: "ആ പെട്ടെന്നുള്ള മഹാദുരന്തം![^1]",
    2: "എന്തൊരു ഭയാനകമാണ് ആ പെട്ടെന്നുള്ള ദുരന്തം!",
    3: "ആ പെട്ടെന്നുള്ള ദുരന്തം എന്താണെന്ന് നിനക്ക് എന്ത് അറിവാണ് നൽകുക?",
    4: "മനുഷ്യർ ആശയക്കുഴപ്പത്തിലായി ചിതറിപ്പറക്കുന്ന ഈയലുകളെപ്പോലെയാകുന്ന ആ ദിവസത്തിൽ (അത് സംഭവിക്കും),",
    5: "പർവ്വതങ്ങൾ മൃദുവായ കമ്പിളി കഷ്ണങ്ങൾ പോലെയായിത്തീരുകയും ചെയ്യും.",
    6: "അപ്പോൾ, ആരുടെ (നന്മകളുടെ) തൂക്കം ത്രാസിൽ കനം തൂങ്ങുന്നുവോ,",
    7: "അവൻ സംതൃപ്തമായ ഒരു ജീവിതാവസ്ഥയിലായിരിക്കും;",
    8: "എന്നാൽ, ആരുടെ തൂക്കമാണോ ത്രാസിൽ കുറഞ്ഞിരിക്കുന്നത്,",
    9: "അവനെ ഒരു അഗാധഗർത്തം വിഴുങ്ങുന്നതായിരിക്കും.[^2]",
    10: "ആ (അഗാധഗർത്തം) എന്താണെന്ന് നിനക്ക് ബോധ്യപ്പെടുത്തി തരുന്നതെന്താണ്?",
    11: "കത്തിജ്ജ്വലിക്കുന്ന അഗ്നിയാണത്![^3]",
}

FOOTNOTES = {
    1: (
        "അതായത്, ഈ പ്രപഞ്ചത്തിന്റെ ഭയാനകമായ "
        "പുനഃക്രമീകരണത്തിന് സാക്ഷ്യം വഹിക്കുന്ന "
        "അന്ത്യദിനത്തിന്റെ ആഗമനം (സൂറഃ 14:48 ലെ "
        "കുറിപ്പ് 63, സൂറഃ 20:105-107 ലെ കുറിപ്പ് "
        "90 എന്നിവ കാണുക)."
    ),
    2: (
        "ഭാഷാർത്ഥത്തിൽ, \"അവന്റെ മാതാവ് (അതായത്, "
        "അവന്റെ അഭയകേന്ദ്രം അല്ലെങ്കിൽ ലക്ഷ്യം) "
        "ഒരു അഗാധഗർത്തമായിരിക്കും.\" ചുരുക്കത്തിൽ, "
        "കഠിനമായ കഷ്ടപ്പാടിന്റെയും നിരാശയുടെയും "
        "അവസ്ഥയാണിത്. ഒന്നിനെ പൂർണ്ണമായി "
        "ഉൾക്കൊള്ളുന്ന അല്ലെങ്കിൽ "
        "മൂടിപ്പൊതിയുന്ന ഒന്നിനെ സൂചിപ്പിക്കാനാണ് "
        "അറബി ശൈലിയിൽ 'ഉമ്മ്' (മാതാവ്/അമ്മ) എന്ന "
        "പദം ഇവിടെ പ്രയോഗിച്ചിരിക്കുന്നത്."
    ),
    3: (
        "ഭാഷാർത്ഥത്തിൽ, \"ചൂടുള്ള അഗ്നി.\" "
        "തീയുടെ ഏറ്റവും തീക്ഷ്ണമായ അവസ്ഥയെ "
        "എടുത്തു കാണിക്കാനാണ് ഈ വിശേഷണം "
        "നൽകിയിരിക്കുന്നത്. പരലോകത്ത് പാപികൾ "
        "അനുഭവിക്കുന്ന കഷ്ടപ്പാടുകളെക്കുറിച്ചുള്ള "
        "ഖുർആനിക വിവരണങ്ങളെല്ലാം മനുഷ്യന്റെ "
        "ഭൗതിക അനുഭവ പരിധിക്കുള്ളിലുള്ള "
        "കാര്യങ്ങളുമായി താരതമ്യം ചെയ്ത് "
        "മനസ്സിലാക്കാൻ സഹായിക്കുന്ന ഉപമകളും "
        "പ്രതീകങ്ങളും മാത്രമാണെന്ന് പ്രത്യേകം "
        "ഓർക്കേണ്ടതുണ്ട് (അനുബന്ധം I കാണുക)."
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
