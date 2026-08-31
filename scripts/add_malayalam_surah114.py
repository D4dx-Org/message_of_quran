"""One-off: insert the Surah 114 (An-Nas) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 5, 6 -- 2 footnotes, matching the 2
footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 114 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah114.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 114

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "An-Nas",
    "malayalam_name": "അന്നാസ്",
    "english_translation": "Men",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "ഈ സൂറത്തുമായി അടുത്ത ബന്ധമുള്ള "
        "തൊട്ടുമുമ്പത്തെ സൂറത്തിന്റെ (സൂറത്ത് "
        "അൽ-ഫലഖ്) ആമുഖക്കുറിപ്പ് കാണുക."
    ),
}

VERSES = {
    1: "പറയുക: മനുഷ്യരുടെ നാഥനോട് ഞാൻ ശരണം തേടുന്നു,",
    2: "മനുഷ്യരുടെ അധിപനോട്,",
    3: "മനുഷ്യരുടെ ദൈവത്തോട്,",
    4: "ഒളിച്ചുനിന്നു ദുർമന്ത്രണം നടത്തുന്നവന്റെ തിന്മയിൽ നിന്ന്,",
    5: "മനുഷ്യരുടെ മനസ്സുകളിൽ ദുർമന്ത്രണം നടത്തുന്നവന്റെ,[^1]",
    6: "അദൃശ്യ ശക്തികളിൽ പെട്ടവരിൽ നിന്നും മനുഷ്യരിൽ നിന്നും (ഉണ്ടാകുന്ന ദുർപ്രേരണകളിൽ നിന്ന്).[^2]",
}

FOOTNOTES = {
    1: "അതായത്, വിശാലമായ അർത്ഥത്തിൽ \"ശൈത്താൻ\" (പിശാച്) എന്ന പദം കൊണ്ട് ഉദ്ദേശിക്കുന്ന ശക്തി (സൂറത്ത് 14, കുറിപ്പ് 31-ൽ റാസിയെ ഉദ്ധരിച്ച് വ്യക്തമാക്കിയത് പോലെ).",
    2: (
        "ജിന്ന് (അൽ-ജിന്ന് എന്നതിന് സമാനമായ) എന്ന "
        "പദത്തിന്റെയും സങ്കൽപ്പത്തിന്റെയും "
        "ഖുർആനിലെ ഏറ്റവും ആദ്യത്തെ "
        "പരാമർശമായിരിക്കാം ഇത്. (ഇതിനെക്കുറിച്ച് "
        "അനുബന്ധം മൂന്നിൽ വിശദീകരിച്ചിട്ടുണ്ട്). ഈ "
        "സന്ദർഭത്തിൽ, മനുഷ്യന്റെ മനസ്സിന് "
        "അനുഭവപ്പെടുന്ന പ്രകൃതിയുടെ അദൃശ്യവും "
        "ദുരൂഹവുമായ ശക്തികളെയായിരിക്കാം ഈ പദം "
        "സൂചിപ്പിക്കുന്നത്; ഇത് ചിലപ്പോൾ ശരിയും "
        "തെറ്റും തിരിച്ചറിയുന്നതിന് മനുഷ്യന് "
        "പ്രയാസമുണ്ടാക്കുന്നു. എന്നിരുന്നാലും, "
        "ഖുർആനിലെ അവസാന സൂറത്തിലെ ഈ അവസാന "
        "സൂക്തത്തിന്റെ വെളിച്ചത്തിൽ, ദൈവത്തോട് "
        "ശരണം തേടാൻ നമ്മോട് ആവശ്യപ്പെട്ടിരിക്കുന്ന "
        "\"അദൃശ്യ ശക്തികൾ\" എന്നത് നമ്മുടെ സ്വന്തം "
        "മനസ്സുകളുടെ അന്ധത, നമ്മുടെ ജഡിക "
        "ആഗ്രഹങ്ങൾ, കൂടാതെ മുൻഗാമികളിൽ നിന്ന് "
        "നമുക്ക് ലഭിച്ചിട്ടുള്ള തെറ്റായ "
        "സങ്കൽപ്പങ്ങളിൽ നിന്നും വ്യാജ "
        "മൂല്യങ്ങളിൽ നിന്നും ഉടലെടുക്കുന്ന "
        "തിന്മയിലേക്കുള്ള ദുർപ്രേരണകളാണെന്നും "
        "നിഗമനം ചെയ്യാം."
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
