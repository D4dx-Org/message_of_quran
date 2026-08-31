"""One-off: insert the Surah 108 (Al-Kawthar) Malayalam translation,
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

Idempotent: deletes any existing surah 108 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah108.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 108

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Al-Kawthar",
    "malayalam_name": "അൽ കൌസർ",
    "english_translation": "Good in Abundance",
    "revelation_period": "കാലം നിർണിതമല്ല",
    "introduction": (
        "ഭൂരിഭാഗം പണ്ഡിതന്മാരും ഈ സൂറത്ത് മക്കാ "
        "കാലഘട്ടത്തിന്റെ തുടക്കത്തിൽ "
        "അവതരിച്ചതാണെന്ന് അഭിപ്രായപ്പെടുമ്പോൾ, ഇത് "
        "മദീനയിലാണ് അവതരിച്ചതെന്നാണ് ഇബ്നു കഥീർ "
        "കൂടുതൽ സാധ്യതയായി കരുതുന്നത്. അനസ് ഇബ്നു "
        "മാലിക്(റ) നിവേദനം ചെയ്ത സ്വഹീഹായ ഒരു "
        "ഹദീസാണ് ഈ നിഗമനത്തിന് (മറ്റു പല "
        "പണ്ഡിതന്മാരും ഇത് പങ്കുവെക്കുന്നു) "
        "അടിസ്ഥാനം. \"ദൈവത്തിന്റെ പ്രവാചകൻ "
        "പള്ളിയിൽ ഞങ്ങളോടൊപ്പമായിരിക്കുമ്പോഴാണ്\" "
        "ഈ സൂറത്ത് അവതരിച്ചത് എന്ന് വ്യക്തമായ "
        "വിശദാംശങ്ങളോടെ അദ്ദേഹം വിവരിക്കുന്നു "
        "(മുസ്ലിം, ഇബ്നു ഹൻബൽ, അബൂദാവൂദ്, നസാഈ). "
        "അനസ് പരാമർശിച്ച \"പള്ളി\" മദീനയിലെ പള്ളി "
        "മാത്രമായിരിക്കാനേ തരമുള്ളൂ. കാരണം, "
        "ഒന്നുകിൽ ആ നഗരവാസിയായ അനസിന് "
        "പ്രവാചകന്റെ മദീനയിലേക്കുള്ള ഹിജ്റയ്ക്ക് "
        "മുമ്പ് അദ്ദേഹത്തെ കാണാൻ സാധിച്ചിരുന്നില്ല "
        "(ആ സമയത്ത് അനസിന് കേവലം പത്ത് വയസ്സ് "
        "മാത്രമായിരുന്നു പ്രായം); അല്ലെങ്കില്‍, "
        "ഹിജ്റ എട്ടാം വർഷത്തിലെ മക്കാ വിജയത്തിന് "
        "മുമ്പ് മുസ്ലിംകൾക്ക് പൊതുവായി സംഘടിത "
        "ആരാധന നടത്താൻ മക്കയിൽ പള്ളികൾ "
        "ലഭ്യമല്ലായിരുന്നു. ഈ സൂറത്തിലെ മൂന്ന് "
        "സൂക്തങ്ങൾ പ്രാഥമികമായി പ്രവാചകനെയും, "
        "അവിടുത്തെ മുഖേന ഓരോ സത്യവിശ്വാസിയായ "
        "സ്ത്രീയെയും പുരുഷനെയുമാണ് അഭിസംബോധന "
        "ചെയ്യുന്നത്."
    ),
}

VERSES = {
    1: "തീർച്ചയായും, നാം നിനക്ക് സമൃദ്ധമായ നന്മകൾ പ്രധാനം ചെയ്തിരിക്കുന്നു:[^1]",
    2: "അതിനാൽ, നിന്റെ നാഥന് വേണ്ടി (മാത്രം) പ്രാർത്ഥിക്കുകയും, (അവന് വേണ്ടി മാത്രം) ബലിയർപ്പിക്കുകയും ചെയ്യുക.",
    3: "തീർച്ചയായും, നിന്നോട് വിദ്വേഷം വെച്ചുപുലർത്തുന്നവൻ ആരോ അവൻ തന്നെയാണ് (എല്ലാ നന്മകളിൽ നിന്നും) വേരറ്റവൻ![^2]",
}

FOOTNOTES = {
    1: (
        "കൗഥർ' എന്ന പദം 'കഥ്റഹ്' എന്ന നാമത്തിന്റെ "
        "തീവ്രരൂപമാണ് (സമഖ്ശരി). ഇതിന്റെ അർത്ഥം "
        "\"സമൃദ്ധി\", \"ധാരാളിത്തം\" അല്ലെങ്കിൽ "
        "\"അളവറ്റത്\" എന്നാണ്. ഖുർആനിൽ ഈ ഒരു "
        "സ്ഥലത്ത് മാത്രമാണ് ഈ പദം "
        "ഉപയോഗിച്ചിട്ടുള്ളത്. ഇവിടെ 'അൽ-കൗഥർ' "
        "എന്നത് പ്രവാചകന് നൽകപ്പെട്ട ദിവ്യബോധനം "
        "(വഹ്‌യ്), അറിവ്, ജ്ഞാനം, സൽപ്രവൃത്തികൾ "
        "ചെയ്യാനുള്ള കഴിവ്, ഇഹലോകത്തിലും "
        "പരലോകത്തിലുമുള്ള ആദരവ് തുടങ്ങിയ "
        "ആത്മീയമായ എല്ലാ നന്മകളുടെയും സമൃദ്ധമായ "
        "ലഭ്യതയെ സൂചിപ്പിക്കുന്നു (റാസി). പൊതുവെ "
        "സത്യവിശ്വാസികളെ സംബന്ധിച്ചിടത്തോളം, "
        "അറിവ് നേടാനും, സൽപ്രവൃത്തികൾ ചെയ്യാനും, "
        "ജീവജാലങ്ങളോട് കരുണ കാണിക്കാനും, അതുവഴി "
        "ആന്തരിക സമാധാനവും ആദരവും "
        "കൈവരിക്കാനുമുള്ള കഴിവിനെ ഇത് "
        "സൂചിപ്പിക്കുന്നു."
    ),
    2: (
        "ഭാഷാർത്ഥത്തിൽ: \"അവൻ തന്നെയാണ് "
        "അറ്റുപപോയവൻ (അബ്തർ)\". ബ്രാക്കറ്റിൽ "
        "നൽകിയിട്ടുള്ള \"എല്ലാ നന്മകളിൽ നിന്നും\" "
        "എന്ന വാചകം ഖാമൂസിലെ വിശദീകരണത്തെ "
        "അടിസ്ഥാനമാക്കിയുള്ളതാണ്."
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
