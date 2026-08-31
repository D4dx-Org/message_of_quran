"""One-off: insert the Surah 97 (Al-Qadr) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 1, 3, 4 [two: 3 and 4], 5 -- 5
footnotes, matching the 5 footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 97 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah97.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 97

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Al-Qadr",
    "malayalam_name": "അൽ ഖദ്ർ",
    "english_translation": "Destiny",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "തൊട്ടുമുൻപത്തെ സൂറത്തിലെ ആദ്യത്തെ അഞ്ച് "
        "വചനങ്ങളുടെ വെളിപാടിനെ — അതായത്, മുഹമ്മദ് "
        "നബിയുടെ പ്രവാചകത്വ ദൗത്യത്തിന്റെ തുടക്കത്തെ — "
        "പരാമർശിച്ചുകൊണ്ട് ആരംഭിക്കുന്ന അൽ-ഖദ്ർ, "
        "തീർച്ചയായും മക്കാ കാലഘട്ടത്തിന്റെ ഏറ്റവും "
        "ആദ്യത്തെ ഭാഗത്ത് ഉൾപ്പെടുന്നതാണ്."
    ),
}

VERSES = {
    1: "നിശ്ചയമായും, നാമിതിനെ (ദിവ്യഗ്രന്ഥത്തെ) വിധിനിർണ്ണയത്തിന്റെ രാത്രിയിലാണ് അവതീർണ്ണമാക്കിയത്.[^1]",
    2: "നിർണ്ണയത്തിന്റെ രാത്രി എന്നാൽ എന്താണെന്ന് നിനക്കെന്തറിയാം?",
    3: "വിധിനിര്‍ണയ രാവ് ആയിരം മാസങ്ങളേക്കാൾ ഉത്തമമാകുന്നു.[^2]",
    4: "അതിൽ കൂട്ടം കൂട്ടമായി മാലാഖമാർ ഇറങ്ങി വരുന്നു,[^3] തങ്ങളുടെ നാഥന്റെ അനുമതിയോടെ ദിവ്യസന്ദേശവും വഹിച്ചു കൊണ്ട്;[^4] സംഭവിക്കാനിടയുള്ള എല്ലാ (തിന്മകളിൽ) നിന്നും,",
    5: "അത് പ്രഭാതോദയം വരെ സുരക്ഷിതമാക്കിത്തീർക്കുന്നു.[^5]",
}

FOOTNOTES = {
    1: (
        "അല്ലെങ്കിൽ: \"സർവ്വശക്തിയുടെ\" അല്ലെങ്കിൽ "
        "\"മഹത്വത്തിന്റെ\" (രാത്രി)— പ്രവാചകന് ആദ്യ "
        "വെളിപാട് ലഭിച്ച രാത്രിയെയാണ് ഇതിലൂടെ "
        "വിശേഷിപ്പിക്കുന്നത് (തൊട്ടുമുമ്പത്തെ "
        "സൂറത്തിന്റെ ആമുഖക്കുറിപ്പ് കാണുക). "
        "പ്രവാചകന്റെ മദീനാ ഹിജ്റയ്ക്ക് പതിമൂന്ന് "
        "വർഷങ്ങൾക്ക് മുമ്പ്, റമദാൻ മാസത്തിലെ "
        "അവസാന പത്തു നാളുകളിൽ ഒന്നിൽ — മിക്കവാറും "
        "ഇരുപത്തിയേഴാം രാവിൽ — ആയിരുന്നു "
        "ഇതെന്നാണ് പല ഹദീസുകളുടെയും അടിസ്ഥാനത്തിൽ "
        "കരുതപ്പെടുന്നത്."
    ),
    2: "അഥവാ, \"സമാനമായ മറ്റൊരു രാത്രിയും ഇല്ലാത്ത (ആയിരം മാസങ്ങൾ) (റാസി).",
    3: (
        "'തനസ്സലു' എന്ന വ്യാകരണ രൂപം ആവർത്തനം, "
        "സാന്ദ്രത അല്ലെങ്കിൽ വലിയ ജനക്കൂട്ടത്തെ/സംഘത്തെ "
        "സൂചിപ്പിക്കുന്നു; അതിനാൽ — ഇബ്‌നു കഥീർ "
        "നിർദ്ദേശിച്ചതുപോലെ — \"സംഘങ്ങളായി/കൂട്ടത്തോടെ "
        "ഇറങ്ങിവരുന്നു\"."
    ),
    4: (
        "ഭാഷാർത്ഥത്തിൽ: \"തന്നെയുമല്ല (ദിവ്യ) "
        "വെളിപാടും\". 'റൂഹ്' എന്ന പദത്തിന്റെ ഈ "
        "പരിഭാഷയ്ക്കായി 16:2-ലെ ആദ്യ വാക്യവും "
        "അതിനുള്ള കുറിപ്പ് 2-ഉം കാണുക. \"ദിവ്യ "
        "വെളിപാട്\" എന്ന അർത്ഥത്തിൽ ഈ പദം ഖുർആനിൽ "
        "ഉപയോഗിച്ചിട്ടുള്ള ഏറ്റവും ആദ്യത്തെ "
        "ഉദാഹരണമാണ് ഇത്."
    ),
    5: (
        "ഭാഷാർത്ഥത്തിൽ, \"അത് രക്ഷയാകുന്നു (സലാം, "
        "സൂറഃ 5 ലെ കുറിപ്പ് 29 കാണുക) — അതായത്, അത് "
        "വിശ്വാസിയെ എല്ലാ ആത്മീയ തിന്മകളിൽ നിന്നും "
        "സുരക്ഷിതനാക്കുന്നു: മുജാഹിദ് (ഇബ്നു കസീർ "
        "ഉദ്ധരിച്ചത്) വ്യക്തമാക്കുന്നത്, ഈ "
        "രാത്രിയുടെ വിശുദ്ധിയെക്കുറിച്ചുള്ള "
        "ബോധപൂർവ്വമായ തിരിച്ചറിവ് മോശമായ "
        "ചിന്തകൾക്കും താല്പര്യങ്ങൾക്കും "
        "എതിരെ ഒരു പരിചയായി പ്രവർത്തിക്കും "
        "എന്നാണ്."
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
