"""One-off: insert the Surah 106 (Quraysh) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 1, 2, 3, 4 -- 4 footnotes, matching
the 4 footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 106 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah106.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 106

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Quraysh",
    "malayalam_name": "അൽ ഖുറയ്ശ്",
    "english_translation": "The Quraysh",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "നബി(സ)യുടെ ചില അനുചരന്മാരുടെയും തൊട്ടടുത്ത "
        "തലമുറയിലെ ചില പണ്ഡിതന്മാരുടെയും "
        "അഭിപ്രായത്തിൽ, ഈ സൂറത്തും ഇതിന് "
        "തൊട്ടുമുമ്പുള്ള സൂറത്തും യഥാർത്ഥത്തിൽ "
        "ഒരൊറ്റ അധ്യായമാണ്. അങ്ങനെ, ഉബയ്യ് ഇബ്നു "
        "കഅബ്(റ)വിന്റെ പക്കലുണ്ടായിരുന്ന ഖുർആൻ "
        "പ്രതിയിൽ 'അൽ-ഫീൽ', 'ഖുറൈശ്' എന്നീ "
        "സൂറത്തുകൾക്കിടയിൽ പതിവുള്ള \"ബിസ്മില്ലാഹി "
        "റഹ്മാനി റഹീം\" (പരമകാരുണികനും "
        "കരുണാനിധിയുമായ ദൈവത്തിന്റെ നാമത്തിൽ) "
        "എന്ന് എഴുതാതെ ഒരൊറ്റ സൂറത്തായിട്ടാണ് "
        "രേഖപ്പെടുത്തിയിരുന്നത് (ബഗവിയും "
        "സമഖ്ശരിയും). അബൂബക്കർ(റ), ഉഥ്മാൻ(റ) "
        "എന്നിവർ ഖുർആന്റെ അന്തിമ ക്രോഡീകരണത്തിനായി "
        "ആശ്രയിച്ച പ്രമുഖ പണ്ഡിതന്മാരിൽ സെയ്ദ് "
        "ഇബ്നു ഥാബിത്, അലി ഇബ്നു അബീത്വാലിബ് "
        "എന്നിവർക്കൊപ്പം ഉബയ്യ് ഇബ്നു കഅബും "
        "ഉണ്ടായിരുന്നുവെന്ന കാര്യം നാം "
        "ഓർക്കേണ്ടതുണ്ട്. ഈ കാരണം കൊണ്ടാകാം ഇബ്നു "
        "ഹജർ അൽ-അസ്ഖലാനി, ഉബയ്യിന്റെ ഖുർആൻ "
        "പ്രതിയിലെ തെളിവ് ഏറെ നിർണ്ണായകമായി "
        "കരുതുന്നത് (ഫത്ഹുൽ ബാരി VIII, 593). "
        "കൂടാതെ, ഉമർ ഇബ്നുൽ ഖത്താബ്(റ) ജമാഅത്ത് "
        "(സംഘടിത) നമസ്കാരത്തിന് നേതൃത്വം "
        "നൽകിയപ്പോൾ ഈ രണ്ട് സൂറത്തുകളും ഒരൊറ്റ "
        "സൂറത്തായി പാരായണം ചെയ്തിരുന്നുവെന്ന് "
        "സ്ഥിരീകരിക്കപ്പെട്ടിട്ടുണ്ട് (സമഖ്ശരിയും "
        "റാസിയും). എന്നാൽ അൽ-ഫീലും ഖുറൈഷും "
        "ഒരൊറ്റ സൂറത്താണോ അതോ രണ്ട് വ്യത്യസ്ത "
        "സൂറത്തുകളാണോ എന്ന കാര്യത്തിൽ അഭിപ്രായ "
        "വ്യത്യാസമുണ്ടെങ്കിലും, രണ്ടാമത്തേത് "
        "ആദ്യത്തേതിന്റെ തുടർച്ചയാണെന്ന കാര്യത്തിൽ "
        "സംശയമില്ല; അതായത്, \"ഖുറൈശികൾ "
        "സുരക്ഷിതരായിരിക്കാൻ വേണ്ടിയാണ്\" ദൈവം "
        "ആനപ്പടയെ നശിപ്പിച്ചത് എന്ന് ഇത് "
        "അർത്ഥമാക്കുന്നു (താഴെയുള്ള വാക്യം ഒന്നും "
        "അതിനോടനുബന്ധിച്ചുള്ള കുറിപ്പും കാണുക)."
    ),
}

VERSES = {
    1: "ഖുറൈശികൾ സുരക്ഷിതരായി തുടരുന്നതിനുവേണ്ടി,[^1]",
    2: "തങ്ങളുടെ ശീതകാല-ഉഷ്ണകാല യാത്രകളിൽ അവർ സുരക്ഷിതരായിരിക്കുന്നതിനും (വേണ്ടി);[^2]",
    3: "അതിനാൽ, ഈ മന്ദിരത്തിന്റെ നാഥനെ അവർ വണങ്ങട്ടെ;[^3]",
    4: "അവർക്ക് വിശപ്പിനെതിരെ ആഹാരം നൽകുകയും, ആപത്തിൽ നിന്ന് അവർക്ക് സുരക്ഷിതത്വം നൽകുകയും ചെയ്തവൻ.[^4]",
}

FOOTNOTES = {
    1: (
        "ഭാഷാർത്ഥത്തിൽ: \"ഖുറൈശികളുടെ "
        "സംരക്ഷണത്തിനായി\", അതായത് കഅബയുടെ "
        "സംരക്ഷകരും, അവസാന പ്രവാചകനായ മുഹമ്മദ് "
        "നബി അവതരിക്കാനിരിക്കുന്ന ഗോത്രവും എന്ന "
        "നിലയിൽ. അതിനാൽ, \"ഖുറൈശികളുടെ "
        "സുരക്ഷിതത്വം\" എന്നത് ദൈവത്തിന്റെ "
        "ഏകത്വത്തിൽ അധിഷ്ഠിതമായ വിശ്വാസത്തിന്റെ "
        "കേന്ദ്രബിന്ദുവായ കഅബയുടെ "
        "സുരക്ഷിതത്വത്തിനുള്ള രൂപകമാണ്; "
        "ഇതിനുവേണ്ടിയാണ് അബ്റഹത്തിന്റെ സൈന്യത്തെ "
        "നശിപ്പിച്ചത് (അമുഖക്കുറിപ്പും "
        "തൊട്ടുമുമ്പത്തെ സൂറത്തും കാണുക)."
    ),
    2: "മക്കയുടെ സമൃദ്ധി അധിഷ്ഠിതമായിരുന്ന രണ്ട് വാർഷിക കച്ചവട സംഘങ്ങളെയാണ് ഇവിടെ സൂചിപ്പിക്കുന്നത് — ശീതകാലത്ത് യമനിലേക്കും ഉഷ്ണകാലത്ത് സിറിയയിലേക്കുമുള്ള യാത്രകൾ.",
    3: "അതായത്, കഅബ (2:125-ലെ കുറിപ്പ് 102 കാണുക).",
    4: "അബ്രാഹാമിന്റെ പ്രാർത്ഥനയോട് സാദൃശ്യമുള്ളത്: \"എന്റെ നാഥാ, ഇതിനെ ഒരു സുരക്ഷിത നഗരമാക്കേണമേ, ഇവിടുത്തെ നിവാസികൾക്ക് ഫലമൂലാദികളാൽ ഉപജീവനം നൽകേണമേ\" (2:126).",
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
