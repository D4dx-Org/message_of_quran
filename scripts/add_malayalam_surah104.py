"""One-off: insert the Surah 104 (Al-Humazah) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 1, 2, 3, 4, 7, 9 -- 6 footnotes,
matching the 6 footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 104 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah104.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 104

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Al-Humazah",
    "malayalam_name": "അൽ ഹുമസ",
    "english_translation": "The Slanderer",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "ഒന്നാമത്തെ വചനത്തിൽ വരുന്ന ഒരു നാമപദത്തിൽ "
        "നിന്നാണ് ഈ സൂറത്തിന് അതിന്റെ പരമ്പരാഗതമായ "
        "പേര് ലഭിച്ചിട്ടുള്ളത്. മുഹമ്മദിന്റെ "
        "പ്രവാചകത്വത്തിന്റെ മൂന്നാം വർഷത്തിന്റെ "
        "അവസാനത്തോടെയാണ് (മിക്കവാറും സൂറഃ 75 "
        "\"അൽഖിയാമ\"യ്ക്ക് ശേഷം) ഇത് "
        "അവതീർണമായതെന്ന് കരുതപ്പെടുന്നു."
    ),
}

VERSES = {
    1: "മറ്റുള്ളവരെ അപകീർത്തിപ്പെടുത്തുന്നവനും കുറ്റങ്ങൾ തിരഞ്ഞുനടക്കുന്നവനുമായ ഏതൊരാൾക്കും നാശം![^1]",
    2: "സമ്പത്ത് സ്വരുക്കൂട്ടുകയും അത് (തനിക്കൊരു) സുരക്ഷാകവചമായി എണ്ണുകയും ചെയ്യുന്ന (അവന് നാശം!)[^2]",
    3: "തന്റെ സമ്പത്ത് തന്നെ എന്നെന്നേക്കും ജീവിക്കാൻ അനുവദിക്കുമെന്ന് അവൻ വിചാരിക്കുന്നു![^3]",
    4: "അല്ല, തീർച്ചയായും (വരാനിരിക്കുന്ന പരലോക ജീവിതത്തിൽ അവനെപ്പോലെയുള്ളവർ) തകർത്തുതരിപ്പണമാക്കുന്ന കഠിനശിക്ഷയിലേക്ക് വലിച്ചെറിയപ്പെടുക തന്നെ ചെയ്യും![^4]",
    5: "ആ തകർത്തുതരിപ്പണമാക്കുന്ന കഠിനശിക്ഷ എന്നാൽ എന്താണെന്ന് നിനക്ക് മനസ്സിലാക്കിത്തരുന്നതെന്താണ്?",
    6: "അത് ദൈവത്താൽ കൊളുത്തപ്പെട്ട അഗ്നിയാകുന്നു,",
    7: "അത് (കുറ്റവാളികളുടെ) ഹൃദയങ്ങൾക്ക് മീതെ പടർന്നുപിടിക്കുന്നതുമാണ്;[^5]",
    8: "തീർച്ചയായും, അത് അവർക്ക് ചുറ്റും അടച്ചുമുദ്രവെയ്ക്കപ്പെടും,",
    9: "അറ്റമില്ലാത്ത സ്തംഭങ്ങൾക്കുള്ളിലായി![^6]",
}

FOOTNOTES = {
    1: "അതായത്, മറ്റുള്ളവരിൽ നിലവിലുള്ളതോ സാങ്കൽപ്പികമായതോ ആയ കുറ്റങ്ങൾ ദുരുദ്ദേശ്യത്തോടെ പുറത്തുകൊണ്ടുവരാൻ ശ്രമിക്കുന്ന ഏതൊരാളും.",
    2: "2-3 വചനങ്ങളിൽ പറയുന്ന നിന്ദ്യമായ മനോഭാവം, ഒന്നാം വചനത്തിൽ പരാമർശിച്ച രണ്ടു കൂട്ടരിൽ നിന്നും തികച്ചും വ്യത്യസ്തമായ മറ്റൊരു വിഭാഗത്തിൽപ്പെടുന്നതുകൊണ്ടാണ് ഈ ആവർത്തനം ചേർത്തിരിക്കുന്നത്.",
    3: (
        "ഭൗതികവസ്തുക്കളും സൗകര്യങ്ങളും "
        "നേടിയെടുക്കുന്നതിനും കൈവശം "
        "വെക്കുന്നതിനും ഏതാണ്ട് ഒരു "
        "\"മതപരമായ\" മൂല്യം കൽപ്പിക്കുന്ന "
        "പ്രവണതയുടെ ഒരു അടയാളമാണിത് — "
        "മനുഷ്യനെ ആത്മീയ ചിന്തകൾക്ക് "
        "യാതൊരുവിധ യഥാർത്ഥ പ്രാധാന്യവും "
        "നൽകുന്നതിൽ നിന്ന് തടയുന്ന ഒരു "
        "പ്രവണതയാണിത് (സൂറഃ 102:1 ലെ കുറിപ്പ് "
        "1 ഒത്തുനോക്കുക). മുൻ വചനത്തിലെ "
        "'അദ്ദദഹു' എന്ന പദത്തെ \"(അവൻ) അത് "
        "ഒരു സുരക്ഷാകവചമായി എണ്ണുന്നു\" "
        "എന്ന് ഞാൻ വിവർത്തനം ചെയ്തത് "
        "ജൗഹരിയുടെ വിശദീകരണത്തെ "
        "അടിസ്ഥാനമാക്കിയാണ്."
    ),
    4: "അൽ-ഹുത്വമഃ' — \"നരകം\" എന്ന ആശയത്തിനുള്ളിൽ ഉൾക്കൊള്ളുന്ന പരലോകത്തെ കഷ്ടപ്പാടുകൾക്കായുള്ള പല പ്രതീകങ്ങളിൽ ഒന്നാണിത് (സൂറഃ 15:43-44 ലെ കുറിപ്പ് 33 കാണുക).",
    5: "അതായത്, അവരുടെ ഹൃദയങ്ങളിൽ നിന്ന് ഉത്ഭവിക്കുന്നത് — അങ്ങനെ പാപികൾ തങ്ങളുടെ കുറ്റബോധം വൈകി തിരിച്ചറിയുമ്പോൾ ഉണ്ടാകുന്ന ആ \"അഗ്നിയുടെ\" ആത്മീയ സ്വഭാവത്തിലേക്ക് ഇത് വ്യക്തമായി വിരൽചൂണ്ടുന്നു.",
    6: "അക്ഷരാർത്ഥത്തിൽ, \"നീട്ടിനീട്ടിയ സ്തംഭങ്ങളിൽ\", അതായത് നിരാശയോടെ മൂടിപ്പൊതിയുന്ന നിലയിൽ.",
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
