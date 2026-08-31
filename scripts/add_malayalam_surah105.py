"""One-off: insert the Surah 105 (Al-Fil) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 1, 4, 5 -- 3 footnotes, matching the
3 footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 105 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah105.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 105

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Al-Fil",
    "malayalam_name": "അൽ ഫീൽ",
    "english_translation": "The Elephant",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "ഒന്നാമത്തെ വചനത്തിൽ പരാമർശിക്കുന്ന "
        "\"ആനക്കൂട്ടം\" എന്നതിൽ നിന്നാണ് ഈ സൂറത്തിന് "
        "ആ പേര് ലഭിച്ചിട്ടുള്ളത്. ക്രിസ്തുവർഷം 570ൽ "
        "മക്കയ്‌ക്കെതിരെ അബിസീനിയ നടത്തിയ സൈനിക "
        "മുന്നേറ്റത്തെയാണ് ഈ സൂറത്ത് "
        "സൂചിപ്പിക്കുന്നത്. അക്കാലത്ത് അബിസീനിയയുടെ "
        "ഭരണത്തിൻ കീഴിലായിരുന്ന യമനിലെ ക്രിസ്ത്യൻ "
        "വൈസ്രോയിയായിരുന്ന അബ്‌റഹ, മക്കയിലെ "
        "കഅ്ബയിലേക്ക് അറബികൾ നടത്തുന്ന വാർഷിക "
        "തീർത്ഥാടനം സ്വയം നിർമ്മിച്ച സനയിലെ വലിയ "
        "ദേവാലയത്തിലേക്ക് തിരിച്ചുവിടാമെന്ന "
        "പ്രതീക്ഷയിൽ ഒരു വലിയ കത്തീഡ്രൽ "
        "പണിതുയർത്തി. എന്നാൽ ആ പ്രതീക്ഷ ഫലിക്കാതെ "
        "വന്നപ്പോൾ അവൻ കഅ്ബ തകർക്കാൻ ഉറപ്പിച്ചു. "
        "അങ്ങനെ പടയാനകൾ ഉൾപ്പെടുന്ന ഒരു കൂറ്റൻ "
        "സൈന്യവുമായി അവൻ മക്കയിലേക്ക് പുറപ്പെട്ടു. "
        "അറബികളെ സംബന്ധിച്ച് അതുവരെ "
        "കണ്ടിട്ടില്ലാത്തതും തികച്ചും "
        "അത്ഭുതകരവുമായ ഒന്നായിരുന്നു അത്. "
        "അതിനാൽത്തന്നെ അക്കാലത്തുള്ളവരും പിൽക്കാല "
        "ചരിത്രകാരന്മാരും ആ വർഷത്തെ \"ആന വർഷം\" "
        "(ആമുൽ ഫീൽ) എന്ന് വിശേഷിപ്പിച്ചു. എന്നാൽ "
        "അബ്‌റഹയുടെ സൈന്യം വഴിമധ്യേ പൂർണ്ണമായും "
        "നശിപ്പിക്കപ്പെട്ടു (ഇബ്നു ഹിശാം, ഇബ്നു "
        "സഅ്ദ് 1/1, 55 അടിക്കുറിപ്പ് കാണുക) - ഇത് "
        "മിക്കവാറും വസൂരിയോ അല്ലെങ്കിൽ ടൈഫസോ "
        "പോലുള്ള അതിതീവ്രമായ ഒരു മഹാമാരി "
        "പടർന്നുപിടിച്ചതിനാലാകാം (താഴെയുള്ള "
        "കുറിപ്പ് 2 കാണുക). അബ്‌റഹ സനയിലേക്ക് "
        "മടങ്ങുന്ന വഴിയിൽ മരണപ്പെടുകയും ചെയ്തു."
    ),
}

VERSES = {
    1: "നിന്റെ നാഥന്‍ ആനപ്പടയെ എന്തു ചെയ്തുവെന്ന് നീ കണ്ടില്ലേ?[^1]",
    2: "അവരുടെ തന്ത്രപൂർവ്വമായ പദ്ധതികളെ അവൻ പൂർണ്ണമായും തകർത്തു തരിപ്പണമാക്കിയില്ലേ?",
    3: "അങ്ങനെ, അവൻ അവർക്ക് മീതെ പറവപ്പറ്റങ്ങളെ അയച്ചു;",
    4: "അവ ആദ്യമേ നിർണ്ണയിക്കപ്പെട്ട കഠിന ശിക്ഷയാകുന്ന കല്ലുകൾ കൊണ്ട് അവരെ പ്രഹരിച്ചു.[^2]",
    5: "അങ്ങനെ അവൻ അവരെ കാലികള്‍ ചവച്ച വൈക്കോൽ പോലെ ആക്കിത്തീർത്തു.[^3]",
}

FOOTNOTES = {
    1: "ഭാഷാർത്ഥത്തിൽ: \"ആനയുടെ ആളുകൾ (അസ്ഹാബുൽ ഫീൽ)\" - ആമുഖ കുറിപ്പ് കാണുക.",
    2: (
        "ഭാഷാർത്ഥത്തിൽ: \"സിജ്ജീൽ കൊണ്ടുള്ള "
        "കല്ലുകൾ കൊണ്ട്\". സൂറഃ 11:82 ലെ കുറിപ്പ് "
        "114-ൽ വിശദീകരിച്ചതുപോലെ, 'സിജ്ജീൽ' എന്നത് "
        "\"എഴുതപ്പെട്ടത്\" അഥവാ രൂപകാലങ്കാരമായി "
        "\"ദൈവത്താൽ നിർണ്ണയിക്കപ്പെട്ടത്\" എന്ന് "
        "അർത്ഥമാക്കുന്ന പദത്തിന് തുല്യമാണ്. "
        "അതിനാൽ, 'ഹിജാറത്തുൻ മിൻ സിജ്ജീൽ' എന്ന "
        "പ്രയോഗം ദൈവത്തിന്റെ വിധിപ്രകാരം "
        "മുൻകൂട്ടി നിശ്ചയിക്കപ്പെട്ട \"ശിക്ഷയാകുന്ന "
        "കല്ലുകളാൽ എറിയൽ\" എന്നതിനെ "
        "സൂചിപ്പിക്കുന്ന രൂപകമാണ്. (സൂറഃ 11:82 ലെ "
        "സമാന പ്രയോഗത്തെക്കുറിച്ചുള്ള "
        "സമഖ്ശരിയുടെയും റാസിയുടെയും "
        "നിരീക്ഷണങ്ങൾ കാണുക). മുകളിൽ പറഞ്ഞ വചനം "
        "സൂചിപ്പിക്കുന്ന പ്രത്യേക ശിക്ഷ, "
        "പെട്ടെന്നുണ്ടായ അതിതീവ്രമായ ഒരു "
        "മഹാമാരിയാണെന്ന് തോന്നുന്നു. വാഖിദിയുടെയും "
        "മുഹമ്മദ് ഇബ്നു ഇസ്ഹാഖിന്റെയും പ്രസ്താവന "
        "പ്രകാരം (ഇബ്നു ഹിശാമും ഇബ്നു കസീറും "
        "ഉദ്ധരിച്ചത്): \"അറബ് മണ്ണിൽ തരിപ്പൻ പനിയും "
        "(ഹസ്ബ) വസൂരിയും (ജുദരി) ആദ്യമായി "
        "പ്രത്യക്ഷപ്പെട്ടത് അപ്പോഴായിരുന്നു\". "
        "'ഹസ്ബ' എന്ന പദത്തിന് (ചില "
        "ഭാഷാപണ്ഡിതരുടെ അഭിപ്രായത്തിൽ ടൈഫസ് "
        "എന്നും അർത്ഥമുണ്ട്) അടിസ്ഥാനപരമായി "
        "\"കല്ലുകൊണ്ട് എറിയുക\" എന്ന "
        "അർത്ഥമാണുള്ളത് എന്നത് ശ്രദ്ധേയമാണ് "
        "(ഖാമൂസ്). 'ത്വയ്ർ' (പറക്കുന്ന ജീവികൾ - "
        "'ത്വാഇർ' എന്നതിന്റെ ബഹുവചനം) എന്ന "
        "നാമപദത്തെക്കുറിച്ച് പറയുമ്പോൾ, അത് "
        "പക്ഷിയാകട്ടെ പ്രാണിയാകട്ടെ \"പറക്കുന്ന "
        "ഏത് ജീവിയെയും\" കുറിക്കുന്ന ഒന്നാണെന്ന് "
        "ഓർക്കേണ്ടതുണ്ട് (താജുൽ അറൂസ്). "
        "ഖുർആനിലോ വിശ്വസനീയമായ ഹദീസുകളിലോ ഈ "
        "\"പറക്കുന്ന ജീവികളുടെ\" "
        "സ്വഭാവത്തെക്കുറിച്ച് ഒരു തെളിവും "
        "നൽകുന്നില്ല. വ്യാഖ്യാതാക്കൾ "
        "നൽകിയിട്ടുള്ള മറ്റ് വിവരണങ്ങൾ കേവലം "
        "ഭാവനയിൽ അധിഷ്ഠിതമായതിനാൽ അവ "
        "ഗൗരവമായി എടുക്കേണ്ടതില്ല. മഹാമാരി എന്ന "
        "അനുമാനം ശരിയാണെങ്കിൽ, ഈ \"പറക്കുന്ന "
        "ജീവികൾ\" (പക്ഷികളോ പ്രാണികളോ ആകട്ടെ) "
        "രോഗാണുക്കളെ പേറുന്നവയായിരുന്നിരിക്കാം. "
        "എന്നാൽ ഒരു കാര്യം വ്യക്തമാണ്: "
        "ആക്രമിക്കാൻ വന്ന സൈന്യത്തെ പിടികൂടിയ "
        "വിനാശം എന്ത് തന്നെയായാലും, അത് "
        "യഥാർത്ഥ അർത്ഥത്തിൽ ഒരു അത്ഭുതം "
        "(ഖുദ്‌റത്ത്) തന്നെയായിരുന്നു - അതായത്, "
        "മക്കയിലെ ദുരിതത്തിലായ ജനങ്ങൾക്ക് അത് "
        "തികച്ചും അപ്രതീക്ഷിതവും "
        "പെട്ടെന്നുള്ളതുമായ രക്ഷയാണ് "
        "എത്തിച്ചുനൽകിയത്."
    ),
    3: "ഈ വിവരണം അടുത്ത സൂറത്തിലും തുടരുന്നുണ്ട്. ചില പണ്ഡിതരുടെ അഭിപ്രായത്തിൽ അടുത്ത സൂറത്ത് ഇതിന്റെ ഒരു ഭാഗം തന്നെയാണ് (സൂറഃ 106-ന്റെ ആമുഖ കുറിപ്പ് കാണുക).",
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
