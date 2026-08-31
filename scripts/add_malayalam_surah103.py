"""One-off: insert the Surah 103 (Al-Asr) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 1, 3 -- 2 footnotes, matching the 2
footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 103 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah103.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 103

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Al-Asr",
    "malayalam_name": "അൽ അസ്ർ",
    "english_translation": "The Flight of Time",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": "സൂറ 94 കഴിഞ്ഞയുടനെ അവതീർണമായത്.",
}

VERSES = {
    1: "സമയത്തിന്റെ ഗതി പരിഗണിക്കുക![^1]",
    2: "തീർച്ചയായും, മനുഷ്യൻ നഷ്ടത്തിലാണ്.",
    3: "സത്യവിശ്വാസം കൈക്കൊള്ളുകയും സല്‍ക്കര്‍മങ്ങളാചരിക്കുകയും പരസ്പരം സത്യമുദ്‌ബോധിപ്പിക്കുകയും ക്ഷമയുപദേശിക്കുകയും ചെയ്തവരൊഴികെ![^2]",
}

FOOTNOTES = {
    1: (
        "'അസ്ർ എന്നാൽ അളക്കാവുന്നതും കാലയളവുകൾ "
        "ചേർന്നതുമായ സമയത്തെയാണ് സൂചിപ്പിക്കുന്നത് "
        "(ആദിയോ അന്തമോ ഇല്ലാത്ത, അനാദിയായ "
        "('ദഹ്ർ') കാലത്തിൽ നിന്ന് വ്യത്യസ്തമായി). "
        "അതിനാൽ, തിരിച്ചുകിട്ടാത്തവിധം വേഗത്തിൽ "
        "കടന്നുപോകുന്ന കാലത്തെയാണ് ഈ പദം ഇവിടെ "
        "അർത്ഥമാക്കുന്നത്."
    ),
    2: "ഭാഷാർത്ഥത്തിൽ: \"തീർച്ചയായും മനുഷ്യൻ നഷ്ടത്തിൽത്തന്നെയാണ്, ഇക്കൂട്ടർ ഒഴികെ...\"",
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
