"""One-off: insert the Surah 110 (An-Nasr) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 2, 3 -- 2 footnotes, matching the 2
footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 110 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah110.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 110

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "An-Nasr",
    "malayalam_name": "അന്നസ്ർ",
    "english_translation": "Succour",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "ഹിജ്റ പത്താം വർഷം ദുൽഹിജ്ജ മാസത്തിൽ "
        "പ്രവാചകന്റെ വിടവാങ്ങൽ ഹജ്ജിനിടയിൽ "
        "മിനായിൽ വെച്ച് അവതരിക്കപ്പെട്ട ഈ സൂറത്ത് — "
        "അവിടുത്തെ മരണത്തിന് രണ്ടു മാസത്തിലേറെ "
        "മുമ്പ് — അവിടുന്ന് ലോകത്തിന് "
        "എത്തിച്ചുനൽകിയ അവസാനത്തെ പൂർണ്ണ "
        "സൂറത്താണ് എന്നതിൽ സംശയമില്ല. ഇതിന് "
        "തലേദിവസം (ദുൽഹിജ്ജ 9 വെള്ളിയാഴ്ച) \"ഇന്ന് "
        "ഞാൻ നിങ്ങൾക്ക് നിങ്ങളുടെ ധാർമ്മിക നിയമം "
        "പൂർത്തിയാക്കിത്തന്നിരിക്കുന്നു, എന്റെ "
        "അനുഗ്രഹങ്ങൾ നിങ്ങൾക്ക് പൂർണ്ണമായി "
        "നൽകുകയും, എനിക്കുള്ള പൂർണ്ണ സമർപ്പണത്തെ "
        "(ഇസ്ലാമിനെ) നിങ്ങളുടെ മതമായി ഞാൻ "
        "തൃപ്തിപ്പെടുകയും ചെയ്തിരിക്കുന്നു\" (5:3) "
        "എന്ന വാക്യം അവതരിച്ചിരുന്നു. അതിനു "
        "തൊട്ടുപിന്നാലെ ഈ സൂറത്ത് അവതരിച്ചതിനാൽ, "
        "പ്രവാചകന്റെ ദൗത്യം പൂർത്തിയായെന്നും "
        "അവിടുത്തെ വേർപാട് അടുത്തുവെന്നും "
        "സ്വഹാബികളിൽ ചിലർ മനസ്സിലാക്കി "
        "(ബുഖാരി). അൻ-നസ്റിന് ശേഷം പ്രവാചകന് "
        "ലഭിച്ച ഒരേയൊരു ദിവ്യബോധനം സൂറത്ത് "
        "അൽ-ബഖറയിലെ സൂക്തം 281 മാത്രമാണ്."
    ),
}

VERSES = {
    1: "ദൈവത്തിന്റെ സഹായവും വിജയവും വന്നണയുകയും,",
    2: "ജനങ്ങൾ കൂട്ടംകൂട്ടമായി ദൈവത്തിന്റെ മതത്തിൽ[^1] പ്രവേശിക്കുന്നത് നീ കാണുകയും ചെയ്താൽ;",
    3: "നിന്റെ നാഥന്റെ അപരിമേയമായ മഹത്വത്തെ വാഴ്ത്തുകയും, അവനെ സ്തുതിക്കുകയും, അവനോട് പാപമോചനം തേടുകയും ചെയ്യുക: തീർച്ചയായും അവൻ പശ്ചാത്താപം സ്വീകരിക്കുന്നവനാകുന്നു.[^2]",
}

FOOTNOTES = {
    1: "അതായത്, ദൈവത്തിലേക്കുള്ള പൂർണ്ണ സമർപ്പണത്തിന്റെ മതം: 3:19 കാണുക — \"തീർച്ചയായും ദൈവത്തിങ്കൽ (അംഗീകൃതമായ) മതം അവനോടുള്ള (മനുഷ്യന്റെ) പൂർണ്ണ സമർപ്പണമാകുന്നു\".",
    2: (
        "ജനങ്ങൾ വൻതോതിൽ സത്യമതത്തിലേക്ക് "
        "കടന്നുവന്നാൽ പോലും ഒരു സത്യവിശ്വാസി "
        "ആത്മസംതൃപ്തിയടയുകയല്ല വേണ്ടത്, മറിച്ച് "
        "കൂടുതൽ വിനയാന്വിതനാകുകയും തന്റെ തന്നെ "
        "വീഴ്ചകളെക്കുറിച്ച് ബോധവാനാകുകയും വേണം "
        "എന്ന് ഇത് സൂചിപ്പിക്കുന്നു. കൂടാതെ, "
        "പ്രവാചകൻ പറഞ്ഞതായി നിവേദനം "
        "ചെയ്യപ്പെട്ടിരിക്കുന്നു: \"അറിയുക, ജനങ്ങൾ "
        "കൂട്ടംകൂട്ടമായി ദൈവത്തിന്റെ മതത്തിൽ "
        "പ്രവേശിച്ചിരിക്കുന്നു — കാലക്രമേണ അവർ "
        "കൂട്ടംകൂട്ടമായിത്തന്നെ അതിൽ നിന്ന് "
        "പുറത്തുപോവുകയും ചെയ്യും\" (ഇബ്നു ഹൻബൽ, "
        "ജാബിർ ഇബ്നു അബ്ദില്ലയിൽ നിന്ന്; "
        "അബൂഹുറൈറയിൽ നിന്നുള്ള സമാനമായ ഹദീസ് "
        "മുസ്തദ്റകിൽ കാണാം)."
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
