"""One-off: insert the Surah 113 (Al-Falaq) Malayalam translation,
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

Idempotent: deletes any existing surah 113 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah113.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 113

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Al-Falaq",
    "malayalam_name": "അൽ ഫലഖ്",
    "english_translation": "The Rising Dawn",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "കൂടുതൽ വ്യാഖ്യാതാക്കളും ഈ സൂറത്തും ഇതിന് "
        "തൊട്ടടുത്ത സൂറത്തും മക്കാ കാലഘട്ടത്തിന്റെ "
        "തുടക്കത്തിൽ അവതരിച്ചതാണെന്ന് "
        "അഭിപ്രായപ്പെടുമ്പോൾ, ചില പ്രമുഖ "
        "പണ്ഡിതന്മാർ (ഉദാഹരണത്തിന് റാസി, ഇബ്നു "
        "കഥീർ) ഇവ മദീനയിലാണ് അവതരിച്ചതെന്ന് "
        "കരുതുന്നു. എന്നാൽ മറ്റു ചിലരാകട്ടെ "
        "(ഉദാഹരണത്തിന് ബഗവി, സമഖ്ശരി, ബൈദാവീ) ഈ "
        "വിഷയത്തിൽ വ്യക്തമായ ഒരു "
        "നിഗമനത്തിലെത്താതെ വിട്ടുനിൽക്കുന്നു. "
        "ലഭ്യമായ അപൂർവ്വം തെളിവുകളുടെ "
        "അടിസ്ഥാനത്തിൽ ഈ രണ്ട് സൂറത്തുകളും മക്കാ "
        "കാലഘട്ടത്തിന്റെ തുടക്കത്തിലുള്ളതാണെന്ന് "
        "കരുതാവുന്നതാണ്."
    ),
}

VERSES = {
    1: "പറയുക: പുലരിയുടെ നാഥനോട് ഞാൻ ശരണം തേടുന്നു,[^1]",
    2: "അവൻ സൃഷ്ടിച്ച സകലതിന്റെയും തിന്മയിൽ നിന്നും,",
    3: "ഇരുൾ മൂടുമ്പോൾ കറുത്ത അന്ധകാരത്തിന്റെ തിന്മയിൽ നിന്നും,[^2]",
    4: "ഗൂഢ തന്ത്രങ്ങളിൽ ഏർപ്പെടുന്ന എല്ലാ മനുഷ്യരുടെയും തിന്മയിൽ നിന്നും,[^3]",
    5: "അസൂയാലു അസൂയപ്പെടുമ്പോൾ അവന്റെ തിന്മയിൽ നിന്നും.[^4]",
}

FOOTNOTES = {
    1: (
        "അൽ-ഫലഖ്' (പ്രഭാതവെളിച്ചം അല്ലെങ്കിൽ "
        "ഉദിച്ചുയരുന്ന പുലരി) എന്ന പദം പലപ്പോഴും "
        "\"(അനിശ്ചിതത്വത്തിന്റെ കാലഘട്ടത്തിന് "
        "ശേഷം) സത്യത്തിന്റെ വെളിപ്പെടലിനെ\" "
        "സൂചിപ്പിക്കാൻ ശൈലിയായി ഉപയോഗിക്കാറുണ്ട് "
        "(താജുൽ അറൂസ്). അതിനാൽ, \"പുലരിയുടെ "
        "നാഥൻ\" എന്ന വിശേഷണം ദൈവമാണ് "
        "സത്യത്തെക്കുറിച്ചുള്ള എല്ലാ "
        "അറിവുകളുടെയും ഉറവിടമെന്നും, അവനോട് "
        "\"ശരണം തേടുക\" എന്നത് സത്യത്തിനായി "
        "പരിശ്രമിക്കുന്നതിന് തുല്യമാണെന്നും "
        "വ്യക്തമാക്കുന്നു."
    ),
    2: (
        "അതായത്, നിരാശയുടെ അല്ലെങ്കിൽ മരണത്തിന്റെ "
        "ആസന്നതയുടെ അന്ധകാരം. ഈ നാല് "
        "സൂക്തങ്ങളിലും (2-5) \"തിന്മ\" (ശർറ്) എന്ന "
        "പദത്തിന് വസ്തുനിഷ്ഠമായ അർത്ഥം മാത്രമല്ല, "
        "വിഷയാധിഷ്ഠിതമായ അർത്ഥവുമുണ്ട് — അതായത്, "
        "തിന്മയെക്കുറിച്ചുള്ള ഭയം."
    ),
    3: (
        "ഭാഷാർത്ഥത്തിൽ, \"കെട്ടുകളിൽ ഊതുന്നവരുടെ "
        "(അൻ-നഫാസാത്) തിന്മകളിൽ നിന്ന്\": "
        "ഇസ്‌ലാമിന് മുൻപുള്ള അറേബ്യയിൽ "
        "നിലവിലുണ്ടായിരുന്ന ഒരു ശൈലിയാണിത്, "
        "അതിനാൽ ക്ലാസിക്കൽ അറബിയിൽ അദൃശ്യമെന്ന് "
        "കരുതപ്പെടുന്ന എല്ലാ ആഭിചാരക്രിയകളെയും "
        "അടയാളപ്പെടുത്താൻ ഇത് ഉപയോഗിക്കുന്നു; "
        "ചൂതുകളിക്കാരും മന്ത്രവാദികളും ഒരു "
        "നൂലിൽ പല കെട്ടുകളിട്ട് അതിലേക്ക് "
        "ഊതുകയും മന്ത്രങ്ങൾ ജപിക്കുകയും ചെയ്യുന്ന "
        "രീതിയിൽ നിന്നായിരിക്കാം ഈ പ്രയോഗം "
        "ഉണ്ടായത്. 'നഫാസാത്' എന്ന വാക്കിന്റെ "
        "സ്ത്രീലിംഗ രൂപം, സമഖ്ശരിയും റാസിയും "
        "ചൂണ്ടിക്കാണിച്ചതുപോലെ, അത് \"സ്ത്രീകളെ\" "
        "മാത്രം സൂചിപ്പിക്കുന്ന ഒന്നല്ല, മറിച്ച് "
        "\"മനുഷ്യരെ\" (അൻഫുസ്, ഏകവചനം: നഫ്സ് - "
        "വ്യാകരണപരമായി സ്ത്രീലിംഗമായ ഒരു "
        "നാമപദം) സൂചിപ്പിക്കുന്നതുമാകാം. മുകളിലെ "
        "വചനത്തിന്റെ വിശദീകരണത്തിൽ, അത്തരം "
        "പ്രവൃത്തികളുടെ യഥാർത്ഥ സ്വഭാവത്തിലും "
        "ഫലപ്രാപ്തിയിലും ഉള്ള എല്ലാ "
        "വിശ്വാസങ്ങളെയും, അതുപോലെ തന്നെ "
        "\"മന്ത്രവാദം\" എന്ന ആശയത്തെയും സമഖ്ശരി "
        "പൂർണ്ണമായി തള്ളിക്കളയുന്നു. "
        "മനഃശാസ്ത്രപരമായ കണ്ടെത്തലുകളുടെ "
        "അടിസ്ഥാനത്തിൽ കൂടുതൽ വിപുലമായ "
        "രീതിയിലാണെങ്കിലും മുഹമ്മദ് അബ്ദുവും "
        "റഷീദ് രിദയും സമാനമായ അഭിപ്രായങ്ങൾ "
        "പ്രകടിപ്പിച്ചിട്ടുണ്ട് (മനാർ I, 398 "
        "മുതലുള്ളവ കാണുക). അത്തരം പ്രവൃത്തികൾ "
        "യുക്തിരഹിതമാണെങ്കിലും അവയിൽ നിന്ന് "
        "\"ദൈവത്തോട് അഭയം തേടാൻ\" വിശ്വാസിയോട് "
        "കൽപ്പിച്ചിരിക്കുന്നതിന്റെ കാരണം — "
        "സമഖ്ശരിയുടെ അഭിപ്രായത്തിൽ — അത്തരം "
        "പരിശ്രമങ്ങളിൽ അടങ്ങിയിരിക്കുന്ന "
        "അന്തർലീനമായ പാപാവസ്ഥയും (സൂറഃ 2, "
        "കുറിപ്പ് 84 കാണുക) അത് ചെയ്യുന്നവരിൽ "
        "ഉണ്ടാക്കിയേക്കാവുന്ന മാനസികമായ "
        "അപകടവുമാണ്."
    ),
    4: (
        "അതായത്, മറ്റൊരു വ്യക്തിയുടെ അസൂയ ഒരാളുടെ "
        "ജീവിതത്തിൽ ഉണ്ടാക്കിയേക്കാവുന്ന "
        "ധാർമ്മികവും സാമൂഹികവുമായ ഫലങ്ങളിൽ "
        "നിന്നും, അതുപോലെ തന്നെ സ്വയം അസൂയ എന്ന "
        "തിന്മയ്ക്ക് ഇരയാകുന്നതിൽ നിന്നും. "
        "ഇതിനോടനുബന്ധിച്ച്, ഖലീഫ ഉമർ ഇബ്നു "
        "അബ്ദിൽ അസീസ് (തന്റെ ഭക്തിയും "
        "ആത്മാർത്ഥതയും കാരണം \"രണ്ടാമത്തെ ഉമർ\" "
        "എന്ന് വിളിക്കപ്പെടുന്നയാൾ) പറഞ്ഞ ഒരു "
        "വാക്ക് സമഖ്ശരി ഉദ്ധരിക്കുന്നുണ്ട്: "
        "\"മറ്റൊരാളോട് അസൂയപ്പെടുന്നവനെക്കാൾ "
        "ദ്രോഹിക്കപ്പെടാൻ സാധ്യതയുള്ള മറ്റൊരു "
        "തെറ്റുകാരനെയും എനിക്ക് സങ്കൽപ്പിക്കാൻ "
        "കഴിയില്ല.\""
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
