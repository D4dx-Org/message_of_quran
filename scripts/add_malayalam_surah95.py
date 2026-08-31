"""One-off: insert the Surah 95 (At-Tin) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 3, 4, 5, 7 -- 4 footnotes, matching
the 4 footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 95 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah95.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 95

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "At-Tin",
    "malayalam_name": "അത്തീൻ",
    "english_translation": "The Fig",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "സൂറഃ 85ന് (\"മഹത്തായ നക്ഷത്രവ്യൂഹങ്ങൾ\") ശേഷം "
        "അവതീർണമായ ഈ സൂറത്ത്, ഒരു മൗലികമായ ധാർമ്മിക "
        "സത്യത്തെ രൂപപ്പെടുത്തുകയും, അത് എല്ലാ യഥാർത്ഥ "
        "മതബോധനങ്ങൾക്കും പൊതുവായുള്ളതാണെന്ന വസ്തുതയെ "
        "ഊന്നിപ്പറയുകയും ചെയ്യുന്നു. ഇതിന്റെ \"പേര്\" — "
        "അല്ലെങ്കിൽ, ഇതറിയപ്പെടുന്ന പ്രധാന വാക്ക് — "
        "ഒന്നാമത്തെ വചനത്തിലെ അത്തിപ്പഴത്തെ (അതായത്, "
        "അത്തിവൃക്ഷത്തെ) കുറിച്ചുള്ള പരാമർശത്തിൽ "
        "നിന്നാണ് സ്വീകരിച്ചിട്ടുള്ളത്."
    ),
}

VERSES = {
    1: "അത്തിപ്പഴത്തെക്കുറിച്ചും ഒലീവിനെക്കുറിച്ചും ചിന്തിക്കുക.",
    2: "സിനായ് പർവ്വതത്തെക്കുറിച്ചും,",
    3: "സുരക്ഷിതമായ ഈ നാട്ടിനെക്കുറിച്ചും![^1]",
    4: "തീർച്ചയായും, മനുഷ്യനെ നാം ഏറ്റവും ഉത്കൃഷ്ടമായ ഘടനയിലാണ് സൃഷ്ടിച്ചിരിക്കുന്നത്;[^2]",
    5: "അതിനുശേഷം, നാം അവനെ അധമരിൽ അധമനാക്കി മാറ്റുകയും ചെയ്തു,[^3]",
    6: "വിശ്വാസമാർജിക്കുകയും സല്‍ക്കര്‍മങ്ങളാചരിക്കുകയും ചെയ്തവർ ഒഴികെ: അവർക്ക് അക്ഷയമായ പ്രതിഫലമുണ്ടായിരിക്കുന്നതാണ്!",
    7: "ഇനി ഇതിനുശേഷവും (ഓ മനുഷ്യാ!) ഈ ധാർമ്മിക നിയമത്തെ കളവാക്കാൻ നിനക്ക് എന്ത് കാരണമാണുള്ളത്?[^4]",
    8: "ദൈവം വിധികര്‍ത്താക്കളില്‍ ഏറ്റം മികച്ച വിധികര്‍ത്താവല്ലയോ?",
}

FOOTNOTES = {
    1: (
        "ഈ സന്ദർഭത്തിൽ \"അത്തിപ്പഴവും\" \"ഒലിവും\" "
        "സൂചിപ്പിക്കുന്നത് ഈ മരങ്ങൾ ധാരാളമായി "
        "കാണപ്പെടുന്ന പ്രദേശങ്ങളെയാണ്: അതായത് "
        "മധ്യധരണ്യാഴിയുടെ കിഴക്കൻ ഭാഗങ്ങളോട് ചേർന്നുള്ള "
        "രാജ്യങ്ങളെ, പ്രത്യേകിച്ച് ഫലസ്തീനും "
        "സിറിയയും. ഖുർആനിൽ പരാമർശിച്ചിട്ടുള്ള "
        "അബ്രാഹാമിക പ്രവാചകന്മാരിൽ ഭൂരിഭാഗവും "
        "ജീവിച്ചിരുന്നതും പ്രബോധനം നടത്തിയതും ഈ "
        "നാടുകളിലായതിനാൽ, ഈ രണ്ട് വൃക്ഷവർഗ്ഗങ്ങളെയും "
        "ആ ദൈവപ്രേരിത മനുഷ്യരുടെ നീണ്ട നിര കൈമാറിയ "
        "മതബോധനങ്ങളുടെ അടയാളമായി കണക്കാക്കാം; ഇതിന്റെ "
        "പൂർത്തീകരണം ജൂത പ്രവാചകന്മാരിലെ അവസാനത്തെ "
        "ആളായ യേശുവിലൂടെയായിരുന്നു. എന്നാൽ \"സിനായ് "
        "പർവ്വതം\" എന്നത് മോശെയുടെ പ്രവാചകത്വത്തെ "
        "പ്രത്യേകം ഊന്നിപ്പറയുന്നു; എന്തെന്നാൽ "
        "മുഹമ്മദിന്റെ വരവിന് മുൻപ് വരെ നിലനിന്നിരുന്നതും "
        "അടിസ്ഥാനപരമായി യേശുവിനും ബാധകമായിരുന്നതുമായ "
        "മതനിയമങ്ങൾ മൂസാ നബിക്ക് വെളിപ്പെടുത്തി "
        "നൽകപ്പെട്ടത് സിനായ് മരുഭൂമിയിലെ ഒരു "
        "പർവ്വതത്തിൽ വെച്ചായിരുന്നു. ഒടുവിൽ, "
        "\"സുരക്ഷിതമായ ഈ നാട്\" എന്നത് സംശയമില്ലാതെ "
        "(സൂറഃ 2:126 ൽ നിന്ന് വ്യക്തമാകുന്നതുപോലെ) "
        "മക്കയെയാണ് സൂചിപ്പിക്കുന്നത്; അവിടെയാണ് "
        "അന്തിമ പ്രവാചകനായ മുഹമ്മദ് നബി ജനിച്ചതും "
        "തന്റെ ദിവ്യമായ ദൗത്യം ലഭിച്ചതും. അങ്ങനെ, 1 "
        "മുതൽ 10 വരെയുള്ള വചനങ്ങൾ ഏകദൈവ വിശ്വാസത്തിന്റെ "
        "ചരിത്രപരമായ മൂന്ന് ഘട്ടങ്ങളിലെയും യഥാർത്ഥ "
        "അധ്യാപനങ്ങളിൽ അടങ്ങിയിരിക്കുന്ന മൗലികമായ "
        "ധാർമ്മിക ഐക്യത്തിലേക്ക് നമ്മുടെ ശ്രദ്ധ "
        "ക്ഷണിക്കുന്നു; മൂസാ, ഈസാ, മുഹമ്മദ് എന്നിവരിലൂടെയാണ് "
        "ഇത് അടയാളപ്പെടുത്തിയിരിക്കുന്നത്. ഇവിടെ "
        "പരിഗണിക്കേണ്ട പ്രത്യേക സത്യം തൊട്ടടുത്ത "
        "മൂന്ന് വചനങ്ങളിൽ പ്രതിപാദിക്കുന്നുണ്ട്."
    ),
    2: (
        "അതായത്, ഈ പ്രത്യേക സൃഷ്ടി നിർവ്വഹിക്കേണ്ട "
        "ധർമ്മങ്ങൾക്ക് അനുസൃതമായി ശാരീരികവും "
        "മാനസികവുമായ എല്ലാ നല്ല ഗുണങ്ങളും "
        "നൽകപ്പെട്ടിരിക്കുന്നു. \"ഏറ്റവും ഉത്കൃഷ്ടമായ "
        "ഘടന\" എന്ന ആശയം ഖുർആന്റെ ഈ പ്രസ്താവനയുമായി "
        "ബന്ധപ്പെട്ടിരിക്കുന്നു; അതായത് അല്ലാഹു "
        "സൃഷ്ടിച്ച മനുഷ്യന്റെ സ്വയമുൾപ്പെടെ (നഫ്സ്) "
        "എല്ലാ കാര്യങ്ങളും \"അത് എന്തായിത്തീരാൻ "
        "ഉദ്ദേശിച്ചതാണോ അതിനനുസൃതമായാണ് "
        "രൂപപ്പെടുത്തിയിരിക്കുന്നത്\" (സൂറഃ 91:7 ഉം "
        "അതിനോടനുബന്ധിച്ചുള്ള 5-ആം കുറിപ്പും കാണുക, "
        "പൊതുവായ അർത്ഥത്തിൽ 87:2 ഉം ഒന്നാം കുറിപ്പും). "
        "എല്ലാ മനുഷ്യർക്കും അവരുടെ ശാരീരികമോ "
        "മാനസികമോ ആയ കഴിവുകളുടെ കാര്യത്തിൽ ഒരേ "
        "\"ഉത്കൃഷ്ട ഘടനയാണ്\" ഉള്ളതെന്ന് ഈ പ്രസ്താവന "
        "ഒട്ടും അർത്ഥമാക്കുന്നില്ല: ഇതിന്റെ ലളിതമായ "
        "അർത്ഥം, ജന്മനാ ലഭിച്ച നേട്ടങ്ങളോ കോട്ടങ്ങളോ "
        "എന്തുതന്നെയായാലും, ഓരോ മനുഷ്യനും തനിക്ക് "
        "സഹജമായി ലഭിച്ച ഗുണങ്ങളെയും താൻ ജീവിക്കുന്ന "
        "സാഹചര്യങ്ങളെയും തനിക്ക് സാധ്യമാകുന്ന ഏറ്റവും "
        "നല്ല രീതിയിൽ ഉപയോഗിക്കാനുള്ള കഴിവ് "
        "നൽകപ്പെട്ടിട്ടുണ്ട് എന്നാണ് (ഇതുമായി "
        "ബന്ധപ്പെട്ട് സൂറഃ 30:30 ഉം അതിനോടനുബന്ധിച്ചുള്ള "
        "കുറിപ്പുകളും, പ്രത്യേകിച്ച് 27, 28 കുറിപ്പുകൾ "
        "കാണുക)."
    ),
    3: (
        "ഈ \"അധമരിൽ അധമനാക്കി മാറ്റുക\" എന്നത് മനുഷ്യൻ "
        "തന്റെ യഥാർത്ഥവും നല്ലതുമായ സ്വഭാവത്തോട് "
        "കാണിച്ച വഞ്ചനയുടെ — മറ്റൊരു വാക്കിൽ പറഞ്ഞാൽ "
        "പിഴവഴിയുടെ — അനന്തരഫലമാണ്: അതായത്, "
        "മനുഷ്യന്റെ സ്വന്തം പ്രവൃത്തികളുടെയും "
        "വീഴ്ചകളുടെയും ഫലം. ഈ \"താഴ്ത്തൽ\" "
        "ദൈവത്തിന്റെ സ്വന്തം പ്രവൃത്തിയായി "
        "പറയുന്നതിനെക്കുറിച്ചുള്ള വിവരണത്തിനായി സൂറഃ "
        "2:7 ലെ കുറിപ്പ് 7 കാണുക."
    ),
    4: (
        "അതായത്, മുൻപത്തെ മൂന്ന് വചനങ്ങളിൽ വിവരിച്ച "
        "ധാർമ്മിക നിയമത്തിന്റെ സാധുതയെ കളവാക്കുക — "
        "എന്റെ അഭിപ്രായത്തിൽ ഈ സന്ദർഭത്തിൽ 'ദീൻ' എന്ന "
        "പദത്തിന്റെ അർത്ഥം ഇതാണ് (ദീൻ എന്ന ഈ പ്രത്യേക "
        "ആശയത്തിനായി സൂറഃ 109:6 ലെ കുറിപ്പ് 3 കാണുക). "
        "മുകളിൽ നൽകിയ ചോദ്യത്തിന് ഈയൊരു അർത്ഥമാണുള്ളത്: "
        "ഇവിടെ പരാമർശിച്ചിരിക്കുന്ന ധാർമ്മിക നിയമം "
        "എല്ലാ ഏകദൈവ വിശ്വാസ മതങ്ങളുടെയും "
        "അധ്യാപനങ്ങളിൽ ഊന്നിപ്പറഞ്ഞിട്ടുള്ളതിനാൽ "
        "(മുകളിലുള്ള 1-3 വചനങ്ങളും കുറിപ്പ് 1 ഉം "
        "ഒത്തുനോക്കുക), അതിന്റെ സത്യം പക്ഷപാതമില്ലാത്ത "
        "ഏതൊരു വ്യക്തിക്കും സ്വയം വ്യക്തമാകേണ്ടതാണ്; "
        "കൂടാതെ, അതിനെ നിഷേധിക്കുന്നത് മനുഷ്യന്റെ "
        "ധാർമ്മികമായ തിരഞ്ഞെടുപ്പിനുള്ള "
        "സ്വാതന്ത്ര്യത്തെ നിഷേധിക്കുന്നതിന് "
        "തുല്യമാണ്, അതുവഴി ദൈവത്തിന്റെ ഭാഗത്തുനിന്നുള്ള "
        "നീതിയെ നിഷേധിക്കലുമാണ് — തൊട്ടടുത്ത വചനം "
        "ചൂണ്ടിക്കാണിക്കുന്നതുപോലെ, ദൈവം സ്വാഭാവികമായും "
        "\"നീതിപാലകരിൽ വെച്ച് ഏറ്റവും വലിയ "
        "നീതിമാനാണ്\"."
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
