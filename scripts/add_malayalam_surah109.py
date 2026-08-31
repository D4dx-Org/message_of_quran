"""One-off: insert the Surah 109 (Al-Kafirun) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 3, 5, 6 -- 3 footnotes, matching the
3 footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 109 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah109.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 109

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Al-Kafirun",
    "malayalam_name": "അൽ കാഫിറൂൻ",
    "english_translation": "Those Who Deny the Truth",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": "സൂറഃ 107-ന് തൊട്ടുപിന്നാലെ അവതീർണമായത്.",
}

VERSES = {
    1: "പറയുക: ഓ സത്യനിഷേധികളേ!",
    2: "നിങ്ങൾ ആരാധിക്കുന്നതിനെ ഞാനൊരിക്കലും ആരാധിക്കുന്നില്ല,",
    3: "ഞാൻ ആരാധിക്കുന്നതിനെ നിങ്ങളും ആരാധിക്കുന്നില്ല![^1]",
    4: "നിങ്ങൾ (ഇതുവരെ) ആരാധിച്ചുപോന്ന യാതൊന്നിനെയും ഞാനൊരിക്കലും ആരാധിക്കുകയുമില്ല,",
    5: "ഞാൻ ആരാധിക്കുന്നതിനെ നിങ്ങളും (ഒരിക്കലും) ആരാധിക്കുകയുമില്ല.[^2]",
    6: "നിങ്ങൾക്ക് നിങ്ങളുടെ ധാർമ്മിക നിയമം, എനിക്ക് എന്റേതും![^3]",
}

FOOTNOTES = {
    1: (
        "ഇവിടെ 'മാ' (\"ഏതൊന്നിനെ\") എന്ന വാക്ക് "
        "ഒരുവശത്ത് അനുകൂലമായ ആശയങ്ങളെയും ധാർമ്മിക "
        "മൂല്യങ്ങളെയും (ഉദാഹരണത്തിന്, ദൈവത്തിലുള്ള "
        "വിശ്വാസവും അവനിലേക്കുള്ള പൂർണ്ണ "
        "സമർപ്പണവും) മറുവശത്ത് തെറ്റായ ആരാധനാ "
        "മൂർത്തികളെയും വ്യാജ മൂല്യങ്ങളെയുമാണ് "
        "സൂചിപ്പിക്കുന്നത് — മനുഷ്യന്റെ വ്യാജമായ "
        "\"സ്വയം പര്യാപ്തതാ\" ബോധം (96:6-7), "
        "അല്ലെങ്കിൽ കൂടുതൽ വേണമെന്ന അതിരറ്റ "
        "ദുരാഗ്രഹം (സൂറത്ത് 102) എന്നിവ ഇതിന് "
        "ഉദാഹരണമാണ്."
    ),
    2: "അതായത്, \"സത്യം നിഷേധിക്കാൻ കാരണമാകുന്ന വ്യാജ മൂല്യങ്ങളെ ഉപേക്ഷിക്കാൻ നിങ്ങൾ തയ്യാറാവാത്തിടത്തോളം കാലം\".",
    3: (
        "അക്ഷരാർത്ഥത്തിൽ: \"എനിക്ക് എന്റെ ധാർമ്മിക "
        "നിയമം\". 'ദീൻ' എന്ന പദത്തിന്റെ പ്രാഥമിക "
        "അർത്ഥം \"അനുസരണം\" എന്നാണ്; പ്രത്യേകിച്ച് "
        "ഒരു നിയമത്തോടുള്ള അനുസരണം അല്ലെങ്കിൽ "
        "ധാർമ്മിക ആധിപത്യമുള്ള ഒരു വ്യവസ്ഥയോടുള്ള "
        "വിധേയത്വം. അതിനാൽ ഇതിന് \"മതം\", "
        "\"വിശ്വാസം\", \"മതനിയമം\" അല്ലെങ്കിൽ "
        "ഇവിടെയും (42:21, 95:7, 98:5, 107:1 "
        "എന്നിവയിലും) സൂചിപ്പിച്ചതുപോലെ "
        "\"ധാർമ്മിക നിയമം\" എന്ന് അർത്ഥം വരുന്നു."
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
