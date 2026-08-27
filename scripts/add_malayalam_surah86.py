"""One-off: insert the Surah 86 (At-Tariq) Malayalam translation,
introduction, and footnotes into the target sqlite file. Markers
cross-checked against the PDF's visible superscripts (7 markers at
verses 1, 4, 6/7, 11, 13, 15, 16), matching the 7 footnote blocks
given, no gaps.

Verses 6 and 7 are combined into one displayed translator line; that
text is duplicated across both verse_number rows here (per the surah
74/77/85 precedent) to keep the 1-17 sequence intact.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 86 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah86.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 86

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "At-Tariq",
    "malayalam_name": "അത്ത്വാരിഖ്",
    "english_translation": "The Night-Star",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "താരതമ്യേന ആദ്യകാലത്ത് (മിക്കവാറും പ്രവാചകത്വത്തിന്റെ "
        "നാലാം വർഷത്തിൽ) അവതരിക്കപ്പെട്ട ഈ സൂറത്തിന്റെ പേര് "
        "അതിന്റെ ഒന്നാമത്തെ വചനത്തിലെ 'അത്ത്വാരിഖ്' എന്ന "
        "നാമപദത്തിൽ നിന്നാണ് എടുത്തിട്ടുള്ളത്."
    ),
}

VERSES = {
    1: "ആകാശത്തെയും രാത്രിയിൽ വരുന്നതിനെയും മുൻനിർത്തി ചിന്തിക്കുക![^1]",
    2: "രാത്രിയിൽ വരുന്നത് എന്താണെന്ന് നിനക്ക് മനസ്സിലാക്കിത്തരുന്നത് എന്താണ്?",
    3: "അത് (ജീവിതത്തിന്റെ) ഇരുൾ തുളഞ്ഞുകയറുന്ന നക്ഷത്രമാകുന്നു;",
    4: "(കാരണം), ഒരു മനുഷ്യനെയും സംരക്ഷകരില്ലാതെ വിട്ടിട്ടില്ല.[^2]",
    5: "അതിനാൽ മനുഷ്യൻ താൻ ഏത് വസ്തുവിൽ നിന്നാണ് സൃഷ്ടിക്കപ്പെട്ടതെന്ന് നോക്കിക്കാണട്ടെ:",
    6: "(പുരുഷന്റെ) നട്ടെല്ലിനും (സ്ത്രീയുടെ) ഇടുപ്പെല്ലിനും ഇടയിൽ നിന്നും പുറപ്പെടുന്ന ഒരു ഇന്ദ്രിയ ദ്രാവകത്തിൽ നിന്നാകുന്നു അവൻ സൃഷ്ടിക്കപ്പെട്ടിരിക്കുന്നത്.[^3]",
    7: "(പുരുഷന്റെ) നട്ടെല്ലിനും (സ്ത്രീയുടെ) ഇടുപ്പെല്ലിനും ഇടയിൽ നിന്നും പുറപ്പെടുന്ന ഒരു ഇന്ദ്രിയ ദ്രാവകത്തിൽ നിന്നാകുന്നു അവൻ സൃഷ്ടിക്കപ്പെട്ടിരിക്കുന്നത്.[^3]",
    8: "തീർച്ചയായും, (മനുഷ്യനെ ആദ്യമായി സൃഷ്ടിച്ച) അവൻ അവനെ വീണ്ടും (ജീവനിലേക്ക്) മടക്കിക്കൊണ്ടുവരാൻ പൂർണ്ണ പ്രാപ്തനാകുന്നു,",
    9: "രഹസ്യങ്ങളെല്ലാം വെളിച്ചത്താക്കപ്പെടുന്ന ആ നാളിൽ,",
    10: "അന്ന് (മനുഷ്യന്) സ്വന്തമായി യാതൊരു ശക്തിയോ സഹായിയോ ഉണ്ടായിരിക്കുകയുമില്ല!",
    11: "എപ്പോഴും ചലിച്ചുകൊണ്ടിരിക്കുന്ന ആകാശത്തെയും മുൻനിർത്തി ചിന്തിക്കുക,[^4]",
    12: "സസ്യങ്ങള്‍ മുളക്കുമ്പോള്‍ പിളരുന്ന ഭൂമിയെയും!",
    13: "തീർച്ചയായും, ഈ (ദൈവിക ഗ്രന്ഥം) സത്യത്തെയും അസത്യത്തെയും വേർതിരിക്കുന്ന ഒരു വചനം തന്നെയാകുന്നു,[^5]",
    14: "ഇത് യാതൊരു തമാശയുമല്ല.",
    15: "തീർച്ചയായും, (ഇതിനെ നിഷേധിക്കുന്ന) അവർ (ഇതിന്റെ യാഥാർത്ഥ്യം തകർക്കാൻ) പലവിധ വ്യാജ തന്ത്രങ്ങളും മെനയുന്നുണ്ട്;[^6]",
    16: "എന്നാൽ ഞാൻ അവരുടെ തന്ത്രങ്ങളെയെല്ലാം പാഴാക്കിക്കളയും.[^7]",
    17: "അതിനാൽ, സത്യനിഷേധികൾക്ക് അവരുടെ വഴിക്ക് പോകാൻ അനുവാദം നൽകുക: കുറച്ചുകാലത്തേക്ക് അവർക്ക് ഒരല്‍പം കൂടി സാവകാശം കൊടുത്തേക്കുക.",
}

FOOTNOTES = {
    1: (
        "ചില വ്യാഖ്യാതാക്കൾ ഇവിടെ 'അത്ത്വാരിഖ്' (രാത്രിയിൽ "
        "വരുന്നത്) എന്ന് വിശേഷിപ്പിച്ചിരിക്കുന്നത് പ്രഭാത "
        "നക്ഷത്രത്തെയാണെന്ന് കരുതുന്നു; കാരണം അത് രാത്രിയുടെ "
        "അവസാന ഭാഗത്താണ് പ്രത്യക്ഷപ്പെടുന്നത്. എന്നാൽ സമഖ്ശരി, "
        "റാഗിബ് തുടങ്ങിയ മറ്റ് ചിലർ ഇതിനെ പൊതുവായ അർത്ഥത്തിലുള്ള "
        "'നക്ഷത്രം' എന്നാണ് മനസ്സിലാക്കുന്നത്. ഈ നാമപദത്തിന്റെ "
        "ഉത്ഭവം പരിശോധിച്ചാൽ, അത് 'ത്വറഖ' (അവൻ ഒന്നിന്മേൽ "
        "അടിച്ചു അല്ലെങ്കിൽ മുട്ടി) എന്ന ക്രിയയിൽ നിന്ന് "
        "ഉണ്ടായതാണെന്ന് കാണാം; 'ത്വറഖൽ ബാബ്' (അവൻ വാതിലിൽ "
        "മുട്ടി) എന്നത് ഇതിന് ഉദാഹരണമാണ്. ആലങ്കാരികമായി, ഈ "
        "പദം 'രാത്രിയിൽ വരുന്ന ഏതിനെയും (അല്ലെങ്കിൽ ആരെയും)' "
        "സൂചിപ്പിക്കുന്നു; കാരണം രാത്രിയിൽ ഒരു വീട്ടിലേക്ക് "
        "വരുന്ന വ്യക്തി വാതിലിൽ മുട്ടുമല്ലോ. ഖുർആനിക ശൈലിയിൽ, "
        "'അത്ത്വാരിഖ്' എന്നത് കഠിനമായ സങ്കടങ്ങളുടെയും "
        "പ്രയാസങ്ങളുടെയും ആഴമേറിയ ഇരുട്ടിൽ അകപ്പെട്ടുപോയ ഒരു "
        "മനുഷ്യന് ലഭിക്കുന്ന സ്വർഗ്ഗീയമായ ആശ്വാസത്തിന്റെ ഒരു "
        "രൂപകമാണ്; അല്ലെങ്കിൽ സംശയങ്ങളുടെ ഇരുട്ടിനെ അകറ്റുന്ന "
        "പെട്ടെന്നുണ്ടാകുന്ന ആന്തരിക ഉണർവാണ്; അതുമല്ലെങ്കിൽ, "
        "മനുഷ്യഹൃദയങ്ങളുടെ വാതിലുകളിൽ മുട്ടുകയും അങ്ങനെ "
        "ആശ്വാസത്തിന്റെയും വെളിച്ചത്തിന്റെയും ധർമ്മം "
        "നിർവ്വഹിക്കുകയും ചെയ്യുന്ന ദൈവീക വെളിപാടാണ്."
    ),
    2: (
        "ഭാഷാർത്ഥത്തിൽ, \"തന്റെ മേൽ ഒരു കാവൽക്കാരൻ (അല്ലെങ്കിൽ "
        "നിരീക്ഷണം) ഇല്ലാത്ത യാതൊരു മനുഷ്യനുമില്ല.\" ഇതുമായി "
        "ബന്ധപ്പെട്ട് സൂറഃ 82:10-12 ലെ 7-ആം കുറിപ്പ് കാണുക."
    ),
    3: (
        "തറാഇബ്' എന്ന ബഹുവചന പദത്തിന് 'വാരിയെല്ലുകൾ' അല്ലെങ്കിൽ "
        "'അസ്ഥികളുടെ ആർച്ച്' എന്നും അർത്ഥമുണ്ട്. അപൂർവ്വമായ "
        "ഖുർആനിക പ്രയോഗങ്ങളുടെ ഉത്ഭവത്തെക്കുറിച്ച് പഠിച്ച "
        "ഭൂരിഭാഗം പണ്ഡിതന്മാരുടെയും അഭിപ്രായപ്രകാരം, ഈ പദം "
        "പ്രത്യേകം സൂചിപ്പിക്കുന്നത് സ്ത്രീ ശരീരഘടനയെയാണ്."
    ),
    4: (
        "അതായത്, \"ദൈവത്തിന്റെ സൃഷ്ടിപ്പിന്റെയും "
        "പുനഃസൃഷ്ടിപ്പിന്റെയും ശക്തി കൂടുതൽ ആഴത്തിൽ "
        "മനസ്സിലാക്കുന്നതിനായി, ചിന്തിക്കുക...\", തുടങ്ങിയവ."
    ),
    5: (
        "ഭാഷാർത്ഥത്തിൽ, \"തീരുമാനമാക്കുന്ന വചനം\" അല്ലെങ്കിൽ "
        "\"വേർതിരിക്കുന്ന വചനം\". അതായത്, ഒരു വശത്ത് "
        "മരണാനന്തര ജീവിതത്തിന്റെ തുടർച്ചയിലുള്ള വിശ്വാസവും, "
        "മറുവശത്ത് അതിന്റെ സാധ്യതയെ നിഷേധിക്കുന്നതും തമ്മിൽ "
        "വേർതിരിക്കുന്നത്. (സൂറഃ 37:21, 44:40, 78:17 തുടങ്ങിയ "
        "സ്ഥലങ്ങളിൽ പുനരുത്ഥാന നാളിനെ 'വേർതിരിവിന്റെ നാൾ' "
        "എന്ന് വിശേഷിപ്പിച്ചിരിക്കുന്നത് കാണുക)."
    ),
    6: (
        "ഭാഷാർത്ഥത്തിൽ, \"പലവിധ തന്ത്രങ്ങൾ മെനയുന്നു \"; "
        "സമാനമായ അർത്ഥത്തിൽ 'മക്ർ' എന്ന പദം ഉപയോഗിച്ചിട്ടുള്ള "
        "സൂറഃ 34:33-ലെ കുറിപ്പ് 41 കാണുക."
    ),
    7: (
        "ഭാഷാർത്ഥത്തിൽ, \"ഞാനും ഒരു തന്ത്രം മെനയും\", അതായത് "
        "\"അവരുടെ തന്ത്രങ്ങളെ ഇല്ലാതാക്കാൻ\". പണ്ഡിതന്മാരുടെ "
        "അഭിപ്രായപ്രകാരം മുകളിൽ നൽകിയ വിവരണമാണ് ഈ വാചകത്തിന് "
        "ഏറ്റവും അനുയോജ്യമായ അർത്ഥം നൽകുന്നത്."
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
