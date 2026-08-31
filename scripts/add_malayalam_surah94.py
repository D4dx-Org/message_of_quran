"""One-off: insert the Surah 94 (Ash-Sharh) Malayalam translation,
introduction, and footnotes into the target sqlite file. The
translator combined verses 2 and 3 into one displayed line
("94:2, 3"); the English database confirms 8 separate verses (2:
"and lifted from thee the burden", 3: "that had weighed so heavily
on thy back?(2)"), so the combined Malayalam text is duplicated
across both verse_number rows here (per the surah 74/77/85/86
precedent), with the [^2] marker placed at the end matching where
the English footnote anchors (end of verse 3).

Markers cross-checked against the PDF's visible superscripts (3
markers at verses 1, 3 [as the "2,3" combined line], 4), matching
the 3 footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 94 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah94.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 94

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Ash-Sharh",
    "malayalam_name": "അലം നശ്റഹ്",
    "english_translation": "Have We Not Opened",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "ഈ സൂറത്ത്, തൊട്ടുമുമ്പത്തെ സൂറത്തിന് തൊട്ടുപിന്നാലെ "
        "അവതരിക്കപ്പെട്ടതാണ്; മാത്രമല്ല, ഇത് അതിന്റെ "
        "നേരിട്ടുള്ള ഒരു തുടർച്ചയാണെന്ന് കാണപ്പെടുന്നു. "
        "ഒന്നാം ഹിജ്റ നൂറ്റാണ്ടിലെ പ്രശസ്തരായ ചില "
        "പണ്ഡിതന്മാർ — ഉദാഹരണത്തിന്, താഊസ് ഇബ്നു കൈസാൻ "
        "അല്ലെങ്കിൽ ഖലീഫ ഉമർ ഇബ്നു അബ്ദിൽ അസീസ് (\"രണ്ടാം "
        "ഉമർ\" എന്നറിയപ്പെടുന്നയാൾ) — അദ്-ദുഹാ, അശ്ശർഹ് "
        "എന്നിവ ഒരൊറ്റ സൂറത്തായി കണക്കാക്കുകയും, "
        "നമസ്കാരത്തിൽ അവ രണ്ടിനുമിടയിൽ രണ്ടാമതൊരു "
        "\"ദൈവനാമത്തിൽ\" ചൊല്ലാതെ ഒരുമിച്ച് ഓതുകയും "
        "ചെയ്തിരുന്നു (റാസി). ഈ വീക്ഷണം അംഗീകരിക്കപ്പെട്ടാലും "
        "ഇല്ലെങ്കിലും, മുൻ സൂറത്തിനെപ്പോലെ തന്നെ ഈ "
        "സൂറത്തും ഒന്നാമതായി പ്രവാചകനെയും, "
        "പ്രവാചകനിലൂടെ ഖുർആന്റെ ഓരോ യഥാർത്ഥ "
        "അനുയായിയെയുമാണ് അഭിസംബോധന ചെയ്യുന്നത് "
        "എന്നതിൽ സംശയമില്ല."
    ),
}

VERSES = {
    1: "നിന്റെ നെഞ്ച് നിനക്ക് നാം വിശാലമാക്കി തന്നില്ലേ?[^1]",
    2: "നിന്റെ മുതുകിനെ അത്രമേൽ ഭാരപ്പെടുത്തിയ ആ ഭാരം നിന്നിൽ നിന്ന് നാം ഇറക്കിവെച്ചു തരികയും ചെയ്തു,[^2]",
    3: "നിന്റെ മുതുകിനെ അത്രമേൽ ഭാരപ്പെടുത്തിയ ആ ഭാരം നിന്നിൽ നിന്ന് നാം ഇറക്കിവെച്ചു തരികയും ചെയ്തു,[^2]",
    4: "നിനക്ക് നിന്റെ പദവി നാം ഉയർത്തിത്തരികയും ചെയ്തു.[^3]",
    5: "എന്നാൽ തീർച്ചയായും, ഓരോ പ്രയാസത്തോടൊപ്പവും ഒരു എളുപ്പമുണ്ട്.",
    6: "തീർച്ചയായും, ഓരോ പ്രയാസത്തോടൊപ്പവും ഒരു എളുപ്പമുണ്ട്!",
    7: "ആകയാൽ, നീ (പ്രയാസങ്ങളിൽ നിന്ന്) ഒഴിവായിക്കഴിഞ്ഞാൽ, ഉറച്ചുനിൽക്കുക.",
    8: "നിന്റെ നാഥനിലേക്ക് മാത്രം സ്നേഹത്തോടെ മനസ്സു തിരിക്കുക.",
}

FOOTNOTES = {
    1: "ഭാഷാർത്ഥത്തിൽ \"നിന്റെ നെഞ്ച്\" അല്ലെങ്കിൽ \"മാറിടം\".",
    2: (
        "അതായത്, \"നിന്റെ മുൻകാല പാപങ്ങളുടെ ഭാരം; അവ "
        "ഇപ്പോൾ പൊറുക്കപ്പെട്ടിരിക്കുന്നു\" (മുജാഹിദ്, "
        "ഖതാദ, ദഹ്ഹാക്, ഇബ്നു സൈദ് എന്നിവരെ ഉദ്ധരിച്ച് "
        "ത്വബരി). മുഹമ്മദ് നബിയുടെ കാര്യത്തിൽ, ഇത് "
        "പ്രവാചകത്വത്തിന് മുമ്പ് സംഭവിച്ച "
        "പിഴവുകളെക്കുറിച്ചുള്ള സൂചനയാണ്. ഇത് 93:7 ലെ "
        "\"അവൻ നിന്നെ വഴി അറിയാത്തവനായി കണ്ടെത്തുകയും, "
        "സന്മാർഗ്ഗം കാണിച്ചുതരികയും ചെയ്തില്ലേ?\" എന്ന "
        "വാക്യത്തിന്റെ പ്രതിധ്വനിയാണ്."
    ),
    3: (
        "അല്ലെങ്കിൽ: \"നിന്റെ കീർത്തി നാം ഉയർത്തിത്തന്നു\". "
        "'ദിക്ർ' എന്ന പദത്തിന്റെ പ്രാഥമിക അർത്ഥം "
        "\"ഓർമ്മപ്പെടുത്തൽ\" അല്ലെങ്കിൽ \"ഓർമ്മ\" "
        "എന്നാണ്. രണ്ടാമതായി, \"ഒന്നിനെക്കുറിച്ചോ "
        "ഒരാളെക്കുറിച്ചോ പ്രശംസയോടെ ഓർമ്മിക്കപ്പെടുന്നത്\" "
        "അതായത് \"കീർത്തി\" അല്ലെങ്കിൽ \"പ്രശസ്തി\" "
        "എന്നും, ഇവിടെ ഉപയോഗിച്ചിരിക്കുന്ന അർത്ഥത്തിൽ "
        "\"ഉന്നതി\" അല്ലെങ്കിൽ \"പദവി\" എന്നതിനെയുമാണ് "
        "ഇത് സൂചിപ്പിക്കുന്നത്."
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
