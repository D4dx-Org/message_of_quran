"""One-off: insert the Surah 99 (Az-Zalzalah) Malayalam translation,
introduction, and footnotes into the target sqlite file. Markers
cross-checked against the PDF's visible superscripts and the English
(Asad) verse text, which both put markers at verses 2, 5, 6 -- 3
footnotes, matching the 3 footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 99 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah99.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 99

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Az-Zalzalah",
    "malayalam_name": "അൽ സൽസല",
    "english_translation": "The Earthquake",
    "revelation_period": "അവതരണകാലം നിർണിതമല്ല",
    "introduction": (
        "ചില പണ്ഡിതന്മാർ ഇതിനെ മക്കാ കാലഘട്ടത്തിൽ "
        "അവതീർണമായതായി കണക്കാക്കുന്നുണ്ടെങ്കിലും, "
        "മിക്കവാറും ഇത് മദീനാ കാലഘട്ടത്തിന്റെ "
        "ആദ്യത്തിൽ അവതീർണമായതാവാനാണ്‌ സാധ്യത."
    ),
}

VERSES = {
    1: "ഭൂമി അതിന്റെ (അവസാനത്തെ) അതിഭയങ്കരമായ പ്രകമ്പനത്താൽ വിറ കൊള്ളുമ്പോൾ,",
    2: "ഭൂമി അതിന്റെയുള്ളിലെ ഭാരങ്ങളെ പുറന്തള്ളുമ്പോള്‍[^1]",
    3: "മനുഷ്യൻ, 'അതിനെന്തു പറ്റി?' എന്ന് നിലവിളിച്ചു ചോദിക്കുമ്പോൾ,",
    4: "ആ നാളിൽ അത് തന്റെ എല്ലാ വൃത്താന്തങ്ങളും വിവരിച്ചു പറയും,",
    5: "നിന്റെ നാഥൻ അങ്ങനെ ചെയ്യാൻ അതിനോട് ബോധനം നൽകിയതിനാലാണത്![^2]",
    6: "അന്ന് മനുഷ്യരെല്ലാം തങ്ങളുടെ (കഴിഞ്ഞകാല) കര്‍മങ്ങള്‍ കാണുന്നതിനു വേണ്ടി, പരസ്പരം വേർപെട്ട നിലയിൽ മുന്നോട്ട് വരും.[^3]",
    7: "അതിനാൽ, ഒരു അണുഅളവ് നന്മ ചെയ്തിട്ടുള്ളവൻ ആരോ, അവൻ അത് കണ്ടറിയും;",
    8: "അണുഅളവ് തിന്മ ചെയ്തിട്ടുള്ളവന്‍ അതും കാണും.\"",
}

FOOTNOTES = {
    1: "അതായത്, അതുവരെ അതിൽ ഒളിഞ്ഞിരുന്നതെല്ലാം, മരിച്ചവരുടെ ശരീരങ്ങളും — അല്ലെങ്കിൽ അവശിഷ്ടങ്ങളും — ഉൾപ്പെടെയുള്ളവ.",
    2: (
        "അതായത്, ന്യായവിധിയുടെ നാളിൽ ഭൂമി മനുഷ്യൻ "
        "ചെയ്ത എല്ലാ കാര്യങ്ങൾക്കും ഒരു സാക്ഷ്യം "
        "എന്നതുപോലെ സാക്ഷി പറയുന്നതാണ്: അബൂഹുറൈറയുടെ "
        "നിവേദനത്തിൽ (ഇബ്നു ഹമ്പലും തിർമിദിയും "
        "ഉദ്ധരിച്ചത്) പ്രവാചകൻ നൽകിയിട്ടുള്ള ഒരു "
        "വിശദീകരണമാണിത്."
    ),
    3: (
        "ഭാഷാർത്ഥത്തിൽ, \"വേർപെട്ട ഘടകങ്ങളായി\" "
        "(അശ്താതൻ). സൂറഃ 6:94 ഒത്തു നോക്കുക — "
        "\"ഇതാ, നാം നിങ്ങളെ ആദ്യതവണ "
        "സൃഷ്ടിച്ചതുപോലെതന്നെ തികച്ചും ഏകാന്തമായ "
        "അവസ്ഥയിൽ നിങ്ങൾ നമ്മുടെ അടുക്കൽ "
        "വന്നിരിക്കുന്നു\": അങ്ങനെ ഓരോ "
        "മനുഷ്യന്റെയും വ്യക്തിപരവും മറ്റൊരാളിലേക്ക് "
        "മാറ്റിവെക്കാൻ കഴിയാത്തതുമായ "
        "ഉത്തരവാദിത്തത്തെ ഇത് ഊന്നിപ്പറയുന്നു."
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
