"""One-off: insert the Surah 112 (Al-Ikhlas) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 2, 4 -- 2 footnotes, matching the 2
footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 112 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah112.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 112

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Al-Ikhlas",
    "malayalam_name": "അൽ ഇഖ്ലാസ്",
    "english_translation": "The Declaration of God's Perfection",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "വിശ്വസനീയമായ ധാരാളം ഹദീസുകളിൽ നിവേദനം "
        "ചെയ്യപ്പെട്ടിട്ടുള്ളതുപോലെ, ഈ സൂറത്ത് "
        "\"മുഴുവൻ ഖുർആന്റെയും മൂന്നിലൊന്നിന് "
        "തുല്യമാണ്\" എന്ന് പ്രവാചകൻ "
        "വിശേഷിപ്പിക്കാറുണ്ടായിരുന്നു (ബുഖാരി, "
        "മുസ്‌ലിം, ഇബ്നു ഹമ്പൽ, അബൂദാവൂദ്, നസാഈ, "
        "തിർമിദി, ഇബ്നു മാജഹ്). മക്കാ "
        "കാലഘട്ടത്തിന്റെ പ്രാരംഭത്തിലാണ് ഇത് "
        "വെളിപ്പെടുത്തപ്പെട്ടതെന്ന് കരുതപ്പെടുന്നു."
    ),
}

VERSES = {
    1: "പറയുക: അവൻ ഏകനായ ദൈവമാകുന്നു:",
    2: "എല്ലാവരാലും ആശ്രയിക്കപ്പെടുന്നവനും, മറ്റാരെയും ആശ്രയിക്കാത്തവനും, സകലത്തിന്റെയും ആദി കാരണവുമായവനാകുന്നു![^1]",
    3: "അവൻ ആരെയും ജനിപ്പിച്ചിട്ടില്ല, ആരാലും ജനിപ്പിക്കപ്പെട്ടിട്ടുമില്ല;",
    4: "അവന് തുല്യനായി യാതൊന്നും തന്നെയില്ല![^2]",
}

FOOTNOTES = {
    1: (
        "ഈ വിവർത്തനം ഖുർആനിൽ ഒരേയൊരു തവണ "
        "മാത്രം വന്നിട്ടുള്ളതും ദൈവത്തിന് "
        "മാത്രം ബാധകവുമായ 'അസ്-സ്വമദ്' എന്ന "
        "പദത്തിന്റെ ഏകദേശ അർത്ഥം മാത്രമാണ് "
        "നൽകുന്നത്. പ്രഥമ കാരണം, നിത്യവും "
        "സ്വതന്ത്രവുമായ അസ്തിത്വം എന്നീ "
        "ആശയങ്ങൾ ഇത് ഉൾക്കൊള്ളുന്നു; അതോടൊപ്പം "
        "നിലവിലുള്ളതോ ചിന്തിക്കാവുന്നതോ ആയ "
        "എല്ലാം അതിന്റെ ഉറവിടമായി അവനിലേക്ക് "
        "തിരിച്ചുപോകുന്നു എന്നും, അതിനാൽ "
        "അതിന്റെ തുടക്കത്തിനും തുടർന്നുള്ള "
        "നിലനിൽപ്പിനും അത് അവനെ "
        "ആശ്രയിച്ചിരിക്കുന്നു എന്നുമുള്ള "
        "ചിന്തയും ഇതിലുണ്ട്."
    ),
    2: (
        "സൂറഃ 89:3 ലെ കുറിപ്പ് 2 ഉം സൂറഃ 19 ലെ "
        "77-ആം കുറിപ്പും ഒത്തുനോക്കുക. ദൈവം എല്ലാ "
        "അർത്ഥത്തിലും ഏകനും സമാനതകളില്ലാത്തവനുമാണ്, "
        "തുടക്കമോ ഒടുവോ ഇല്ലാത്തവനാണ് എന്ന "
        "വസ്തുതയുടെ യുക്തിസഹമായ തുടർച്ചയാണ് "
        "\"അവന് തുല്യനായി യാതൊന്നും "
        "തന്നെയില്ല\" എന്ന പ്രസ്താവനയിലുള്ളത് — "
        "ഇത് അവനെ വിവരിക്കാനോ നിർവ്വചിക്കാനോ "
        "ഉള്ള ഏതൊരു സാധ്യതയെയും തടയുന്നു (സൂറഃ "
        "6:100 ലെ അവസാന വാക്യത്തിന്റെ കുറിപ്പ് "
        "88 കാണുക). തൽഫലമായി, അവന്റെ "
        "അസ്തിത്വത്തിന്റെ സ്വഭാവം മനുഷ്യന്റെ "
        "മനസ്സിലാക്കലിനോ ഭാവനയ്ക്കോ "
        "അപ്പുറത്താണ്: രൂപപരമായ "
        "ചിത്രീകരണങ്ങളിലൂടെയോ അമൂർത്തമായ "
        "പ്രതീകങ്ങളിലൂടെയോ പോലും ദൈവത്തെ "
        "\"ചിത്രീകരിക്കാനുള്ള\" ഏതൊരു ശ്രമവും "
        "സത്യത്തെ നിഷേധിക്കുന്ന കടുത്ത "
        "ധിക്കാരമായി കണക്കാക്കേണ്ടി വരുന്നത് "
        "എന്തുകൊണ്ടാണെന്ന് ഇത് വിശദീകരിക്കുന്നു."
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
