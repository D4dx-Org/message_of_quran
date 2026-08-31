"""One-off: insert the Surah 107 (Al-Ma'un) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 1, 3, 5, 7 -- 4 footnotes, matching
the 4 footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 107 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah107.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 107

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Al-Ma'un",
    "malayalam_name": "അൽ മാഊൻ",
    "english_translation": "Assistance",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "പ്രവാചകത്വത്തിന്റെ ആദ്യവർഷങ്ങളിൽ "
        "(മിക്കവാറും സൂറത്ത് 102-ന് ശേഷം) "
        "അവതരിക്കപ്പെട്ട ഈ സൂറത്തിന്റെ പേര്, ഇതിലെ "
        "അവസാന സൂക്തത്തിൽ കാണുന്ന 'അൽ-മാഊൻ' എന്ന "
        "വാക്കിൽ നിന്നാണ് സ്വീകരിച്ചിട്ടുള്ളത്. 4 "
        "മുതൽ 7 വരെയുള്ള സൂക്തങ്ങൾ മദീനയിലാണ് "
        "അവതരിച്ചതെന്ന ചില വ്യാഖ്യാതാക്കളുടെ "
        "അഭിപ്രായത്തിന് ചരിത്രപരമോ "
        "പാഠനാർഹമായതോ ആയ തെളിവുകളൊന്നുമില്ല, "
        "അതിനാൽ അത് തള്ളിക്കളയാവുന്നതാണ്."
    ),
}

VERSES = {
    1: "ധാർമ്മിക നിയമങ്ങളെ തികച്ചും വ്യാജമാക്കുന്ന (തരത്തിലുള്ള മനുഷ്യനെ) നീ കണ്ടിട്ടുണ്ടോ?[^1]",
    2: "നോക്കൂ, അനാഥയെ ആട്ടിയകറ്റുന്നത് അങ്ങനെയുള്ള (ഒരു മനുഷ്യൻ) തന്നെയാണ്,",
    3: "അഗതിക്ക് ആഹാരം നൽകാൻ പ്രേരിപ്പിക്കാത്തവനുമാണ്.[^2]",
    4: "എന്നാൽ, പ്രാർത്ഥിക്കുന്നവർക്ക് നാശം!",
    5: "തങ്ങളുടെ പ്രാർത്ഥനയുടെ അന്തസ്സത്തയിൽ നിന്ന് മനസ്സുകൊണ്ട് അകന്നുനിൽക്കുന്നവർക്ക്,[^3]",
    6: "ആളുകളെ കാണിക്കാനും പ്രശംസ പിടിച്ചുപറ്റാനും മാത്രം ആഗ്രഹിക്കുന്നവർക്ക്,",
    7: "കൂടാതെ, (തങ്ങളുടെ സഹജീവികൾക്ക്) എല്ലാവിധ സഹായങ്ങളും വിലക്കുന്നവർക്ക്![^4]",
}

FOOTNOTES = {
    1: (
        "അതായത്, മതം എന്ന സങ്കൽപ്പത്തിനോ, അത് "
        "മുന്നോട്ടുവെക്കുന്ന ധാർമ്മിക "
        "നിയമങ്ങൾക്കോ ('ദീൻ' എന്ന പദത്തിന്റെ "
        "പ്രാഥമിക അർത്ഥങ്ങളിലൊന്ന് - 109:6-ലെ "
        "കുറിപ്പ് 3 കാണുക) യാതൊരു വസ്തുനിഷ്ഠമായ "
        "സാധുതയുമില്ലെന്ന് നിഷേധിക്കുന്നവൻ. "
        "എന്നാൽ ചില വ്യാഖ്യാതാക്കൾ ഇവിടെ 'ദീൻ' "
        "എന്നാൽ \"പ്രതിഫല നാൾ\" (ന്യായാധിവിധിയുടെ "
        "ദിനം) ആണെന്നും, \"പ്രതിഫല നാളിനെ "
        "വ്യാജമാക്കുന്നവൻ\" എന്നാണ് ഈ "
        "വാചകത്തിന്റെ അർത്ഥമെന്നും "
        "അഭിപ്രായപ്പെടുന്നു."
    ),
    2: "ഭാഷാർത്ഥത്തിൽ, \"പ്രേരിപ്പിക്കുന്നില്ല\", അതായത് സ്വയം പ്രേരിപ്പിക്കുന്നില്ല.",
    3: "ഭാഷാർത്ഥത്തിൽ, \"തങ്ങളുടെ പ്രാർത്ഥനകളെക്കുറിച്ച് (ബോധപൂർവ്വം) അശ്രദ്ധരായവർ\"",
    4: (
        "'അൽ-മാഊൻ' എന്ന പദത്തിൽ ഒരാളുടെ ദൈനംദിന "
        "ജീവിതത്തിന് ആവശ്യമായ പല ചെറിയ "
        "സാധനങ്ങളും, അത്തരം സാധനങ്ങൾ നൽകി "
        "സഹജീവികളെ സഹായിക്കുന്ന "
        "കാരുണ്യപ്രവൃത്തികളും ഉൾപ്പെടുന്നു. "
        "അതിന്റെ വിശാലമായ അർത്ഥത്തിൽ, ഏതൊരു "
        "പ്രതിസന്ധിഘട്ടത്തിലും നൽകുന്ന "
        "\"സഹായം\" അല്ലെങ്കിൽ \"പിന്തുണ\"യെയാണ് "
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
