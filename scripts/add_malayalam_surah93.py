"""One-off: insert the Surah 93 (Ad-Duha) Malayalam translation,
introduction, and footnotes into the target sqlite file. Markers
cross-checked against the PDF's visible superscripts (5 markers at
verses 2, 3, 6, 10, 11), matching the 5 footnote blocks given, no
gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 93 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah93.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 93

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Ad-Duha",
    "malayalam_name": "അദ്‌ദുഹാ",
    "english_translation": "The Bright Morning Hours",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "സൂറഃ 89 (അൽ-ഫജ്‌ർ) അവതീർണമായതിന് ശേഷം, "
        "പ്രവാചകന് കുറച്ചുകാലത്തേക്ക് യാതൊരു വെളിപാടും "
        "ലഭിക്കാതിരുന്ന ഒരു സമയമുണ്ടായതായും, ആ അവസരത്തിൽ "
        "മക്കയിലെ അദ്ദേഹത്തിന്റെ എതിരാളികൾ \"നിന്റെ ദൈവം "
        "നിന്നെ കൈവിട്ടിരിക്കുന്നു, വെറുത്തിരിക്കുന്നു!\" "
        "എന്ന് പറഞ്ഞ് അദ്ദേഹത്തെ പരിഹസിച്ചതായും "
        "പറയപ്പെടുന്നു — അതിനുപിന്നാലെയാണ് ഈ സൂറത്ത് "
        "അവതീർണമായത്. സംശയാസ്പദമായ ഈ കഥ നാം "
        "സ്വീകരിച്ചാലും ഇല്ലെങ്കിലും, ഈ സൂറത്ത് "
        "പ്രഥമദൃഷ്ട്യാ പ്രവാചകനെ അഭിസംബോധന "
        "ചെയ്യുന്നതാണെങ്കിലും, ഇതിന് വളരെ വിപുലമായ ഒരു "
        "ലക്ഷ്യമുണ്ടെന്ന് അനുമാനിക്കാൻ എല്ലാ "
        "കാരണങ്ങളുമുണ്ട്: നന്മ ചെയ്യുന്നവരെയും "
        "നിരപരാധികളെയും പലപ്പോഴും ബാധിക്കുന്ന "
        "ദുഃഖങ്ങളാലും കഠിനമായ ദുരിതങ്ങളാലും കഷ്ടപ്പെടുന്ന, "
        "ചിലപ്പോഴൊക്കെ നീതിമാന്മാരെപ്പോലും ദൈവത്തിന്റെ "
        "പരമമായ നീതിയെ ചോദ്യം ചെയ്യാൻ പ്രേരിപ്പിക്കുന്ന "
        "രീതിയിലുള്ള വിഷമതകൾ അനുഭവിക്കുന്ന ഏതൊരു "
        "വിശ്വാസിയായ പുരുഷനെയും സ്ത്രീയെയും "
        "ആശ്വസിപ്പിക്കാൻ ഉദ്ദേശിച്ചുള്ളതാണ് ഇത്."
    ),
}

VERSES = {
    1: "പ്രഭാതത്തിലെ പ്രകാശത്തെക്കുറിച്ച് ചിന്തിക്കുക.",
    2: "മന്ദം മന്ദം ഇരുണ്ടുവരുന്ന രാവിനെക്കുറിച്ച് ചിന്തിക്കുക,[^1]",
    3: "നിന്റെ നാഥൻ നിന്നെ വെടിഞ്ഞിട്ടില്ല, വെറുത്തിട്ടുമില്ല.[^2]",
    4: "തീർച്ചയായും പരലോകമാണ് (നിന്റെ ജീവിതത്തിന്റെ) ഈ ആദ്യഭാഗത്തേക്കാൾ നിനക്ക് ഏറ്റവും ഉത്തമമായിട്ടുള്ളത്.",
    5: "തീർച്ചയായും വൈകാതെ (നിന്റെ മനസ്സ് ആഗ്രഹിക്കുന്നത്) നിന്റെ നാഥന്‍ നിനക്ക് നൽകുന്നതാണ്, അങ്ങനെ നീ തൃപ്തനാവുകയും ചെയ്യും.",
    6: "അവൻ നിന്നെ ഒരു അനാഥയായി കണ്ടെത്തുകയും, അതിനു സംരക്ഷണം നൽകുകയും ചെയ്തില്ലേ?[^3]",
    7: "അവൻ നിന്നെ വഴി അറിയാത്തവനായി കണ്ടെത്തുകയും, സന്മാർഗ്ഗം കാണിച്ചുതരികയും ചെയ്തില്ലേ?",
    8: "അവൻ നിന്നെ ദരിദ്രനായി കണ്ടെത്തുകയും, സമൃദ്ധിയുള്ളവനാക്കുകയും ചെയ്തില്ലേ?",
    9: "ആകയാൽ, അനാഥയോട് നീ അക്രമം കാണിക്കരുത്.",
    10: "(നിന്റെ) സഹായം തേടിവരുന്നവനെ നീ ഒരിക്കലും ആട്ടിയകറ്റരുത്.[^4]",
    11: "നിന്റെ നാഥന്റെ അനുഗ്രഹങ്ങളെക്കുറിച്ച് നീ (എപ്പോഴും) സംസാരിക്കുക.[^5]",
}

FOOTNOTES = {
    1: (
        "\"പ്രഭാതത്തിലെ പ്രകാശം\" എന്ന പ്രയോഗം "
        "പ്രത്യക്ഷത്തിൽ സൂചിപ്പിക്കുന്നത് "
        "മനുഷ്യജീവിതത്തിലെ വളരെ കുറഞ്ഞതും "
        "ഇടവിട്ടുണ്ടാകുന്നതുമായ സന്തോഷത്തിന്റെ "
        "നിമിഷങ്ങളെയാണ്; ഇതിന് വിപരീതമായാണ് \" മന്ദം "
        "മന്ദം ഇരുണ്ടുവരുന്ന രാത്രി\" എന്ന "
        "ദൈർഘ്യമേറിയ പ്രയോഗം വരുന്നത്, അതായത് ഈ "
        "ലോകത്ത് മനുഷ്യന്റെ നിലനിൽപ്പിന് മുകളിൽ "
        "പൊതുവെ നിഴൽ വീഴ്ത്തുന്ന നീണ്ട ദുഃഖങ്ങളുടെയോ "
        "കഷ്ടപ്പാടുകളുടെയോ കാലഘട്ടങ്ങൾ (സൂറഃ 90:4 "
        "ഒത്തുനോക്കുക). രാത്രിക്ക് പിന്നാലെ പ്രഭാതം "
        "വരുന്നത് എത്രത്തോളം ഉറപ്പാണോ, അതുപോലെ "
        "ദൈവത്തിന്റെ കാരുണ്യം ഏതൊരു കഷ്ടപ്പാടിനെയും "
        "ലഘൂകരിക്കുക തന്നെ ചെയ്യും എന്നൊരു ആഴത്തിലുള്ള "
        "അർത്ഥം കൂടി ഇതിലുണ്ട് — ഒന്നുകിൽ ഈ ലോകത്ത്, "
        "അല്ലെങ്കിൽ വരാനിരിക്കുന്ന പരലോക ജീവിതത്തിൽ. "
        "കാരണം ദൈവം \"തന്റെ മേൽ കൃപയുടെയും "
        "കാരുണ്യത്തിന്റെയും നിയമം "
        "നിശ്ചയിച്ചിരിക്കുന്നു\" (സൂറഃ 6:12 ഉം 54 ഉം)."
    ),
    2: "അതായത്, ദൈവം നിന്നെക്കൊണ്ട് സഹിപ്പിക്കാൻ ഉദ്ദേശിച്ച ദുരിതങ്ങൾ കണ്ടുകൊണ്ട് വിവേകരഹിതരായ ആളുകൾ നിഗമനം ചെയ്തേക്കാവുന്നത് പോലെ.",
    3: (
        "മുഹമ്മദ് നബി ജനിച്ചത് പിതാവിന്റെ മരണത്തിന് "
        "ഏതാനും മാസങ്ങൾക്ക് ശേഷമാണെന്നതും, അദ്ദേഹത്തിന് "
        "ആറ് വയസ്സുള്ളപ്പോൾ മാതാവ് മരണപ്പെട്ടു "
        "എന്നുമുള്ള യാഥാർത്ഥ്യത്തിലേക്കുള്ള ഒരു "
        "സൂചനയാകാം ഇത്. എന്നാൽ ഇതുകൂടാതെ, ഓരോ "
        "മനുഷ്യനും ഒരു അർത്ഥത്തിൽ \"അനാഥൻ\" "
        "തന്നെയാണ്; കാരണം ഓരോരുത്തരും \"ഏകാകിയായ "
        "അവസ്ഥയിലാണ് സൃഷ്ടിക്കപ്പെട്ടിരിക്കുന്നത്\" "
        "(cf. 6:94), പുനരുത്ഥാന നാളിൽ ദൈവത്തിന് മുന്നിൽ "
        "\"ഏകാകിയായിത്തന്നെ പ്രത്യക്ഷപ്പെടുകയും "
        "ചെയ്യും\" (19:95)."
    ),
    4: (
        "സാഇൽ' എന്ന പദത്തിന്റെ ഭാഷാർത്ഥം "
        "\"ചോദിക്കുന്നവൻ\" എന്നാണ്. ഇത് ഒരു "
        "\"യാചകനെ\" മാത്രമല്ല സൂചിപ്പിക്കുന്നത്; "
        "ശാരീരികമോ ധാർമ്മികമോ ആയ പ്രയാസകരമായ "
        "സാഹചര്യങ്ങളിൽ സഹായം ചോദിക്കുന്നവരെയോ, "
        "അറിവും വെളിച്ചവും തേടിവരുന്നവരെയോ ഒക്കെ ഇത് "
        "അർത്ഥമാക്കുന്നു."
    ),
    5: "അതായത്, \"നിന്റെ കഷ്ടപ്പാടുകളെക്കുറിച്ച് പറയുന്നതിന് പകരം (ദൈവത്തിന്റെ അനുഗ്രഹങ്ങളെക്കുറിച്ച് സംസാരിക്കുക)\".",
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
