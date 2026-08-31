"""One-off: insert the Surah 92 (Al-Layl) Malayalam translation,
introduction, and footnotes into the target sqlite file. Markers
cross-checked against the PDF's visible superscripts (8 markers at
verses 3, 4, 6, 7, 8, 11, 13, 19), matching the 8 footnote blocks
given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 92 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah92.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 92

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Al-Layl",
    "malayalam_name": "അൽ ലയ്ൽ",
    "english_translation": "The Night",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "കാലഗണനാ ക്രമത്തിൽ മിക്കവാറും ഒൻപതാമത്തേതായി — "
        "ഏറ്റവും ആദ്യകാല വെളിപാടുകളിൽ ഒന്നായി ഏകകണ്ഠമായി "
        "കണക്കാക്കപ്പെടുന്ന ഈ സൂറത്തിന്റെ പേര്, അതിന്റെ "
        "ഒന്നാമത്തെ വചനത്തിലെ 'അൽ-ലയ്‌ൽ' (രാത്രി) എന്ന "
        "പരാമർശത്തെ അടിസ്ഥാനമാക്കിയുള്ളതാണ്."
    ),
}

VERSES = {
    1: "ഇരുട്ടിൽ (ഭൂമിയെ) മൂടിക്കളയുന്ന രാത്രിയെക്കുറിച്ച് ചിന്തിക്കുക,",
    2: "വെളിച്ചത്തോടെ ഉദിച്ചുയരുന്ന പകലിനെക്കുറിച്ചും!",
    3: "ആണും പെണ്ണുമായി സൃഷ്ടിച്ചതിനെക്കുറിച്ചും![^1]",
    4: "തീർച്ചയായും, (ഓ മനുഷ്യരേ,) നിങ്ങളുടെ പ്രയത്‌നങ്ങള്‍ ബഹുവിധമാകുന്നു.[^2]",
    5: "അതിനാൽ, (മറ്റുള്ളവർക്ക്) നൽകുകയും ദൈവത്തെക്കുറിച്ച് ബോധവാനായിരിക്കുകയും ചെയ്തവൻ ആരോ,",
    6: "പരമമായ നന്മയുടെ സത്യത്തിൽ വിശ്വസിക്കുകയും ചെയ്തവൻ ആരോ[^3]",
    7: "അവന് (ആത്യന്തികമായ) എളുപ്പത്തിലേക്കുള്ള വഴി നാം സൌകര്യപ്പെടുത്തിക്കൊടുക്കുന്നതാണ്.[^4]",
    8: "എന്നാൽ പിശുക്ക് കാണിക്കുകയും, താൻ സ്വയംപര്യാപ്തനാണെന്ന് കരുതുകയും ചെയ്തവൻ ആരോ,[^5]",
    9: "പരമമായ സത്യത്തെ കളവാക്കി തള്ളുകയും ചെയ്തവൻ ആരോ —",
    10: "അവന് നാം ദുര്‍ഘടമായതിലേക്ക് വഴിയൊരുക്കിക്കൊടുക്കുന്നതാണ്:",
    11: "അവൻ (തന്റെ കുഴിമാടത്തിലേക്ക്) പോകുമ്പോൾ അവന്റെ ധനം അവന് എന്ത് പ്രയോജനമാണുണ്ടാക്കുക?[^6]",
    12: "തീർച്ചയായും, (നിങ്ങൾക്ക്) സന്മാർഗ്ഗം അരുളുക എന്നത് നമ്മുടെ ബാധ്യതയത്രേ;",
    13: "തീർച്ചയായും, വരാനിരിക്കുന്ന ജീവിതത്തിന്റെയും അത് പോലെ (നിങ്ങളുടെ ജീവിതത്തിന്റെ) ആദ്യഭാഗത്തിന്റെയും മേൽ (ആധിപത്യം നമുക്കുള്ളത് തന്നെയാണ്).[^7]",
    14: "അതിനാൽ ആളിക്കത്തുന്ന നാരാകാഗ്നിയെക്കുറിച്ച് ഞാൻ നിങ്ങൾക്ക് മുന്നറിയിപ്പ് നൽകുന്നു",
    15: "പരമ നിർഭാഗ്യവാനായ ആ ദുഷ്ടനല്ലാതെ മറ്റാരും അതിൽ വെന്തുരുകേണ്ടി വരികയില്ല,",
    16: "സത്യത്തെ നിഷേധിക്കുകയും (അതിൽ നിന്ന്) തിരിഞ്ഞുകളയുകയും ചെയ്തവൻ.\"",
    17: "എന്നാൽ ദൈവത്തെക്കുറിച്ച് യഥാർത്ഥ ബോധമുള്ളവൻ അതിൽ നിന്നും അകലെയായിരിക്കും:",
    18: "ആത്മവിശുദ്ധി കൈവരിക്കുന്നതിനായി തന്റെ സമ്പത്ത് (മറ്റുള്ളവർക്കായി) ചെലവഴിക്കുന്നവൻ;",
    19: "അവൻ അത് ചെയ്യുന്നത് തനിക്ക് ലഭിച്ച ഏതെങ്കിലും ഔദാര്യത്തിനുള്ള പ്രത്യുപകാരമായിട്ടല്ല.[^8]",
    20: "തന്റെ അത്യുന്നതനായ നാഥന്റെ പ്രീതി കാംക്ഷിച്ചുകൊണ്ട് മാത്രം.",
    21: "തീർച്ചയായും ദൈവം അവനിൽ സംപ്രീതനാവുകയും ചെയ്യും.",
}

FOOTNOTES = {
    1: (
        "ഭാഷാർത്ഥത്തിൽ, \"ആണിനെയും പെണ്ണിനെയും "
        "സൃഷ്ടിച്ചതിനെ (അല്ലെങ്കിൽ സൃഷ്ടിക്കുന്നതിനെ) "
        "മുൻനിർത്തി ചിന്തിക്കുക\", അതായത് ആണും പെണ്ണും "
        "തമ്മിലുള്ള വ്യത്യാസങ്ങൾക്ക് കാരണമായ ഘടകങ്ങൾ. "
        "ഇത്, രാത്രിയുടെയും പകലിന്റെയും, ഇരുളിന്റെയും "
        "വെളിച്ചത്തിന്റെയും പ്രതീകാത്മകതയോടൊപ്പം — "
        "തൊട്ടുമുൻപത്തെ സൂറത്തിലെ ആദ്യത്തെ പത്ത് "
        "വചനങ്ങൾക്ക് സമാനമായി — പ്രകൃതിയിലുടനീളം "
        "പ്രകടമായ ധ്രുവീകരണത്തിലേക്കുള്ള ഒരു "
        "വിരൽചൂണ്ടലാണ്; അതിനാൽ, മനുഷ്യന്റെ "
        "ലക്ഷ്യങ്ങളുടെയും പ്രേരണകളുടെയും സവിശേഷതയായ "
        "വൈരുദ്ധ്യത്തിലേക്കുള്ള (തൊട്ടടുത്ത വചനത്തിൽ "
        "പറയുന്ന) ഒരു സൂചനയുമാണിത്."
    ),
    2: (
        "അതായത്, നല്ലതും ചീത്തയുമായ ലക്ഷ്യങ്ങളിലേക്ക് "
        "(സൂറഃ 91:8 ലെ കുറിപ്പ് 6 കാണുക) — അതായത്, "
        "\"അതിനാൽ നിങ്ങളുടെ പ്രവൃത്തികളുടെ "
        "അനന്തരഫലങ്ങളും, അനിവാര്യമായും, "
        "വ്യത്യസ്തമായിരിക്കും."
    ),
    3: (
        "അതായത്, കാലത്തിനും സാമൂഹിക സാഹചര്യങ്ങൾക്കും "
        "അതീതമായ ധാർമ്മിക മൂല്യങ്ങളിൽ വിശ്വസിക്കുക, "
        "അതിനാൽ \"ധാർമ്മികമായ അനിവാര്യത\" എന്ന് "
        "വിശേഷിപ്പിക്കാവുന്ന കാര്യങ്ങളുടെ സമ്പൂർണ്ണ "
        "സാധുതയിൽ വിശ്വസിക്കുക."
    ),
    4: "സൂറഃ 87:8 ലെ കുറിപ്പ് 6 കാണുക.",
    5: "സൂറഃ 96:6-7 ഒത്തുനോക്കുക.",
    6: "അല്ലെങ്കിൽ (ഒരു പ്രസ്താവന എന്ന നിലയിൽ): \"അവൻ താഴേക്ക് പോകുമ്പോൾ അവന്റെ ധനം അവന് യാതൊരു പ്രയോജനവും ചെയ്യുകയില്ല...\", എന്നിങ്ങനെ.",
    7: "ഈ പ്രസ്താവന ലക്ഷ്യമാക്കുന്നത്, മനുഷ്യന്റെ ഈ ലോകത്തെ ജീവിതവും പരലോക ജീവിതവും ഒരേ തുടർച്ചയായ നിലനിൽപ്പിന്റെ രണ്ട് ഘട്ടങ്ങൾ മാത്രമാണെന്ന വസ്തുതയെ ഊന്നിപ്പറയാനാണ്.",
    8: (
        "ഭാഷാർത്ഥത്തിൽ, \"പ്രതിഫലം നൽകപ്പെടേണ്ട യാതൊരു "
        "ഉപകാരവും ഒരാളും അവന് ചെയ്തിട്ടില്ലാത്ത നിലയിൽ\". "
        "ഭാവിയിലേക്ക് വിരൽചൂണ്ടുന്ന ഇതിന്റെ ഏറ്റവും "
        "വിപുലമായ അർത്ഥത്തിൽ, ഈ വാചകം ഒരു "
        "പ്രതിഫലത്തെക്കുറിച്ചുള്ള പ്രതീക്ഷയെയും "
        "സൂചിപ്പിക്കുന്നുണ്ട്."
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
