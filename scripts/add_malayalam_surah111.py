"""One-off: insert the Surah 111 (Al-Masad) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 1, 3, 4, 5 -- 4 footnotes, matching
the 4 footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 111 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah111.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 111

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Al-Masad",
    "malayalam_name": "അൽ മസദ്",
    "english_translation": "The Twisted Strands",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "അവതരണ ക്രമത്തിൽ ആറാമത്തേതായ, വളരെ "
        "ആദ്യകാലത്ത് അവതരിക്കപ്പെട്ട ഈ സൂറത്തിന്റെ "
        "പേര് ഇതിലെ അവസാന വാക്കിൽ നിന്നാണ് "
        "സ്വീകരിച്ചിട്ടുള്ളത്. പ്രവാചകന്റെ "
        "സന്ദേശത്തോടുള്ള അദ്ദേഹത്തിന്റെ "
        "പിതൃസഹോദരനായ അബൂലഹബിന് "
        "എപ്പോഴുമുണ്ടായിരുന്ന കടുത്ത "
        "ശത്രുതയെക്കുറിച്ചാണ് ഇത് "
        "പരാമർശിക്കുന്നത്: തന്റെ ജന്മസിദ്ധമായ "
        "അഹങ്കാരം, വലിയ ധനത്തിലുള്ള അഹങ്കാരം, "
        "കൂടാതെ എല്ലാ മനുഷ്യരും ദൈവത്തിന് മുന്നിൽ "
        "തുല്യരാണെന്നും അവരവരുടെ കർമ്മങ്ങളുടെ "
        "അടിസ്ഥാനത്തിൽ മാത്രമേ ദൈവം വിചാരണ "
        "ചെയ്യുകയുള്ളൂവെന്നുമുള്ള മുഹമ്മദ് "
        "മുന്നോട്ടുവെച്ച ആശയത്തോടുള്ള വിമുഖത "
        "എന്നിവയിലായിരുന്നു ഈ ശത്രുതയുടെ വേരുകൾ "
        "(സൂറത്തിലെ ആദ്യ സൂക്തത്തെക്കുറിച്ചുള്ള "
        "ത്വബരിയുടെ വ്യാഖ്യാനത്തിൽ ഇബ്നു സെയ്ദിനെ "
        "ഉദ്ധരിച്ച് വ്യക്തമാക്കുന്നത്). ബുഖാരിയും "
        "മുസ്ലിമും ഉൾപ്പെടെയുള്ള വിശ്വാസയോഗ്യരായ "
        "പല പ്രമുഖരും നിവേദനം ചെയ്തതുപോലെ: ഒരു "
        "ദിവസം പ്രവാചകൻ മക്കയിലെ അസ്-സ്വഫ കുന്നിൻ "
        "മുകളിൽ കയറി തന്റെ ഗോത്രമായ ഖുറൈശികളിൽ "
        "കേൾക്കാൻ കഴിയുന്ന എല്ലാവരെയും "
        "വിളിച്ചുകൂട്ടി. അവർ ഒന്നിച്ചുകൂടിയപ്പോൾ "
        "അവിടുന്ന് ചോദിച്ചു: \"ഓ അബ്ദുൽ "
        "മുത്വലിബിന്റെ മക്കളേ! ഓ ഫിഹ്റിന്റെ "
        "മക്കളേ! ആ കുന്നിന് പിന്നിൽ നിന്ന് ശത്രു "
        "യോദ്ധാക്കൾ നിങ്ങളുടെ മേൽ പതിക്കാൻ "
        "പോകുന്നു എന്ന് ഞാൻ നിങ്ങളോട് പറഞ്ഞാൽ, "
        "നിങ്ങൾ എന്നെ വിശ്വസിക്കുമോ?\" അവർ മറുപടി "
        "പറഞ്ഞു: \"അതെ, ഞങ്ങൾ വിശ്വസിക്കും.\" "
        "അപ്പോൾ അവിടുന്ന് പറഞ്ഞു: \"എങ്കിൽ അറിയുക, "
        "വരാനിരിക്കുന്ന അന്ത്യസമയത്തെക്കുറിച്ച് "
        "(ഖിയാമത്ത് നാൾ) മുന്നറിയിപ്പ് നൽകാനാണ് "
        "ഞാൻ ഇവിടെ വന്നിരിക്കുന്നത്!\" ഇതുകേട്ട "
        "അബൂലഹബ് വിളിച്ചുപറഞ്ഞു: "
        "\"ഇതിനുവേണ്ടിയാണോ നീ ഞങ്ങളെ "
        "വിളിച്ചുകൂട്ടിയത്? നിനക്ക് നാശം!\" "
        "ഇതിനുശേഷമാണ് ഈ സൂറത്ത് അവതരിച്ചത്."
    ),
}

VERSES = {
    1: "ശോഭയുള്ള മുഖമുള്ളവന്റെ കൈകൾ നശിക്കട്ടെ,[^1] അവനും നശിക്കട്ടെ!",
    2: "അവന്റെ ധനമോ അവൻ സമ്പാദിച്ചതൊന്നുമോ അവന് ഉപകരിച്ചില്ല!",
    3: "(വരാനിരിക്കുന്ന ജീവിതത്തിൽ) ജ്വാലകളുയരുന്ന നരകത്തില്‍ അവൻ വെന്തുരുകേണ്ടിവരും;[^2]",
    4: "ദുഷ്ടകഥകൾ ചുമന്നുനടക്കുന്ന അവന്റെ ഭാര്യയും,[^3]",
    5: "കഴുത്തിൽ പിണഞ്ഞ നാരുകൊണ്ടൊരു വടമുമായി അവളും (വന്നെത്തും)![^4]",
}

FOOTNOTES = {
    1: (
        "പ്രവാചകന്റെ ഈ പിതൃ സഹോദരന്റെ യഥാർത്ഥ "
        "പേര് അബ്ദുൽ ഉസ്സ എന്നായിരുന്നു. "
        "അദ്ദേഹത്തിന്റെ സൗന്ദര്യവും, പ്രത്യേകിച്ച് "
        "ശോഭയുള്ള മുഖവും കാരണം അദ്ദേഹം അബൂലഹബ് "
        "(ഭാഷാർത്ഥത്തിൽ, \"ജ്വാലയുടെ ഉടമ\") എന്ന "
        "പേരിൽ ജനപ്രിയനായി അറിയപ്പെട്ടു "
        "(മുഖാതിലിനെ ഉദ്ധരിച്ച് ബഗവി; സമഖ്ശരി, "
        "റാസി, ഫത്ഹുൽ ബാരി VIII, 599). "
        "ഇസ്ലാമിന്റെ ആഗമനത്തിന് മുമ്പുതന്നെ ഈ "
        "വിളിപ്പേര് അദ്ദേഹത്തിന് "
        "നൽകപ്പെട്ടിരുന്നതിനാൽ, ഇതിന് നിന്ദ്യമായ "
        "ഒരു അർത്ഥമുണ്ടായിരുന്നുവെന്ന് "
        "കരുതേണ്ടതില്ല. — ക്ലാസ്സിക്കൽ അറബിക് "
        "ശൈലിയനുസരിച്ച്, ഇവിടെ \"കൈകൾ\" എന്ന പദം "
        "അബൂലഹബ് പ്രയോഗിച്ച വലിയ സ്വാധീനത്തെയും "
        "\"അധികാരത്തെയും\" സൂചിപ്പിക്കുന്ന "
        "രൂപകമാണ്."
    ),
    2: "നാറൻ ദാത ലഹബ്' (ആളിക്കത്തുന്ന തീ) എന്ന പ്രയോഗം അബൂലഹബ് എന്ന വിളിപ്പേരിന്റെ അർത്ഥത്തെ അടിസ്ഥാനമാക്കിയുള്ള ഒരു പദപ്രയോഗമാണ്.",
    3: (
        "ഭാഷാർത്ഥത്തിൽ: \"വിറക് ചുമക്കുന്നവൾ\". "
        "\"അവർക്കിടയിൽ വിദ്വേഷത്തിന്റെ ജ്വാലകൾ "
        "കൊളുത്തുന്നതിനായി\" രഹസ്യമായി "
        "ദുർവർത്തമാനങ്ങളും അപവാദങ്ങളും ഒരാളിൽ "
        "നിന്ന് മറ്റൊരാളിലേക്ക് ചുമക്കുന്നവരെ "
        "സൂചിപ്പിക്കാൻ ഉപയോഗിക്കുന്ന "
        "പ്രശസ്തമായ ഒരു ശൈലിയാണിത് (സമഖ്ശരി; "
        "ത്വബരി ഉദ്ധരിച്ച ഇക്'രിമ, മുജാഹിദ്, "
        "ഖത്താദ എന്നിവരും കാണുക). ഈ സ്ത്രീയുടെ "
        "പേര് അർവ ഉമ്മു ജമീൽ ബിൻത് ഹർബ് ഇബ്നു "
        "ഉമയ്യ എന്നായിരുന്നു; അവർ അബൂസുഫ്യാന്റെ "
        "സഹോദരിയും, ഉമയ്യദ് രാജവംശത്തിന്റെ "
        "സ്ഥാപകനായ മുആവിയയുടെ "
        "പിതൃസഹോദരിയുമായിരുന്നു. മുഹമ്മദ് "
        "നബിയോടും അവിടുത്തെ അനുയായികളോടുമുള്ള "
        "അവരുടെ വിദ്വേഷം എത്രത്തോളമെന്നാൽ, "
        "അവിടുത്തേക്ക് ഉപദ്രവമുണ്ടാക്കുകയെന്ന "
        "ലക്ഷ്യത്തോടെ ഇരുട്ടിന്റെ മറവിൽ "
        "പ്രവാചകന്റെ വീടിന് മുന്നിൽ മുള്ളുകൾ "
        "വിതറുമായിരുന്നു. കൂടാതെ തന്റെ "
        "വാക്ചാതുരി ഉപയോഗിച്ച് പ്രവാചകനെയും "
        "അവിടുത്തെ സന്ദേശത്തെയും നിരന്തരം "
        "അധിക്ഷേപിക്കുകയും ചെയ്തിരുന്നു."
    ),
    4: (
        "മസദ്' എന്ന പദം കൊണ്ട് ഉദ്ദേശിക്കുന്നത് "
        "ഏത് വസ്തു കൊണ്ടുണ്ടാക്കിയതാണെങ്കിലും, "
        "പിരിച്ചെടുത്ത നൂലുകൾ അല്ലെങ്കിൽ ചരടുകൾ "
        "അടങ്ങിയ ഏതിനെയും സൂചിപ്പിക്കുന്നു "
        "(ഖാമൂസ്, മുഗ്നി, ലിസാനുൽ അറബ്). ഇവിടെ "
        "ഉപയോഗിച്ചിരിക്കുന്ന അരൂപമായ അർത്ഥത്തിൽ, "
        "ഈ വാചകത്തിന് ഇരട്ട അർത്ഥമുണ്ട്: ഇത് ആ "
        "സ്ത്രീയുടെ വക്രവും വികൃതവുമായ "
        "സ്വഭാവത്തെ സൂചിപ്പിക്കുന്നു, ഒപ്പം "
        "\"ഓരോ മനുഷ്യന്റെയും വിധി അവന്റെ "
        "കഴുത്തിൽ ബന്ധിക്കപ്പെട്ടിരിക്കുന്നു\" "
        "(17:13 കാണുക) എന്ന ആത്മീയ സത്യത്തെയും "
        "വെളിപ്പെടുത്തുന്നു — ഇത് രണ്ടാം "
        "സൂക്തത്തോടൊപ്പം ഈ സൂറത്തിന്റെ പൊതുവായ, "
        "കാലാതീതമായ സന്ദേശത്തെ "
        "എടുത്തുകാണിക്കുന്നു."
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
