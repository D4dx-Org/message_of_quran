"""One-off: insert the Surah 100 (Al-Adiyat) Malayalam translation,
introduction, and footnotes into the target sqlite file. No PDF was
provided for this surah (plain text only), so marker positions were
cross-checked against the English (Asad) verse text, which has
explicit (N) markers at verses 1, 5, 6 -- 3 footnotes, matching the
3 footnote blocks given, no gaps.

Schema-aware, same as add_malayalam_surah69.py onward: if the target's
malayalam_footnotes table has a surah_number column (MOQ Backend
staging), footnote_number resets to 1 per surah. If not (the app's
bundled sqlite), footnote_number continues that table's pool-wide
counter instead.

Idempotent: deletes any existing surah 100 Malayalam rows first, safe to re-run.

    python scripts/add_malayalam_surah100.py <path-to-sqlite>
"""
import re
import sqlite3
import sys

CHAPTER = 100

SURAH = {
    "id": CHAPTER,
    "chapter_number": CHAPTER,
    "arabic_name": "Al-Adiyat",
    "malayalam_name": "അൽ ആദിയാത്ത്",
    "english_translation": "The Chargers",
    "revelation_period": "മക്കയിൽ അവതരിച്ചത്",
    "introduction": (
        "സൂറഃ 103-ന് ശേഷം അവതരിക്കപ്പെട്ടത്. "
        "\"കുതിരപ്പടയാളികളുടെ\" (പ്രതീകാത്മകതയെക്കുറിച്ചുള്ള "
        "വിവരണത്തിനായി താഴെയുള്ള കുറിപ്പ് 2 കാണുക."
    ),
}

VERSES = {
    1: "ഓ,[^1] കിതച്ചുപായുകയും കുതിരകൾ",
    2: "തീപ്പൊരികൾ പറത്തുകയും,",
    3: "പിന്നെ പുലര്‍വേളയില്‍ കടന്നാക്രമിക്കാനായി പാഞ്ഞടുക്കുന്നവ,",
    4: "അതിലൂടെ പൊടിപറത്തുകയും,",
    5: "അങ്ങനെ ഏതൊരു സംഘത്തിലേക്കും (അന്ധമായി) ഇരച്ചുകയറുന്നവ തന്നെയാണ് സത്യം![^2]",
    6: "തീർച്ചയായും, മനുഷ്യൻ തന്റെ നാഥനോട് കടുത്ത നന്ദികേട് കാണിക്കുന്നവനാകുന്നു.[^3]",
    7: "തീർച്ചയായും, ഇതിന് അവൻ (സ്വയം) അതിന് സാക്ഷ്യം വഹിക്കുന്നവനുമാണ്:",
    8: "തീർച്ചയായും അവൻ ധനത്തോട് കഠിനമായ സ്നേഹമുള്ളവനാകുന്നു.",
    9: "എന്നാൽ അവൻ അറിയുന്നില്ലേ, (അന്ത്യനാളിൽ) കല്ലറകളിലുള്ളതെല്ലാം ഉയിർത്തെഴുന്നേൽപ്പിക്കപ്പെടുകയും പുറത്തുകൊണ്ടുവരപ്പെടുകയും ചെയ്യുമ്പോൾ,",
    10: "മനുഷ്യരുടെ ഹൃദയങ്ങളിൽ (ഒളിഞ്ഞിരിക്കുന്ന) എല്ലാ കാര്യങ്ങളും വെളിപ്പെടുത്തപ്പെടുമ്പോൾ",
    11: "ആ നാളിൽ തങ്ങളുടെ നാഥൻ അവരെക്കുറിച്ച് എപ്പോഴും പൂർണ്ണമായി അറിയുന്നവനായിരുന്നു (എന്ന് അവൻ വ്യക്തമാക്കുമെന്ന്)?",
}

FOOTNOTES = {
    1: (
        "തുടർന്നുവരുന്ന വാക്യങ്ങൾ ഉപമാരൂപത്തിലുള്ളതും "
        "സാങ്കൽപ്പികവുമായ ഒരു സാഹചര്യത്തെ "
        "പരാമർശിക്കുന്നതിനാലാണ് 'വാ' എന്ന ശപഥ "
        "അക്ഷരത്തെ ഞാൻ സാധാരണയായി നൽകാറുള്ള "
        "\"മുൻനിർത്തി ചിന്തിക്കുക\" എന്നതിനോ മിക്ക "
        "വിവർത്തനങ്ങളിലും കാണുന്ന \"തന്നെയാണ് "
        "സത്യം\" എന്നതിനോ പകരം \"ഓ\" എന്ന് ഇവിടെ "
        "കൂടുതൽ അനുയോജ്യമായി വിവർത്തനം "
        "ചെയ്തിരിക്കുന്നത്."
    ),
    2: (
        "അതായത്, പൊടിപടലങ്ങളാൽ കണ്ണ് "
        "കാണാതാവുകയും തങ്ങളുടെ ആക്രമണം മിത്രത്തിന് "
        "നേരെയോ ശത്രുവിന് നേരെയോ എന്ന് "
        "അറിയാതിരിക്കുകയും ചെയ്യുക. മുകളിലെ "
        "അഞ്ച് വചനങ്ങളിൽ വികസിപ്പിച്ചെടുത്ത "
        "പ്രതീകാത്മക ചിത്രം അതിന്റെ തുടർച്ചയുമായി "
        "അടുത്ത ബന്ധമുള്ളതാണ്; എങ്കിലും ഈ "
        "ബന്ധം ക്ലാസിക്കൽ വ്യാഖ്യാതാക്കൾ "
        "ഒരിക്കലും വ്യക്തമാക്കിയിട്ടില്ല. "
        "'അൽ-ആദിയാത്ത്' എന്ന പദം നിസ്സംശയമായും "
        "സൂചിപ്പിക്കുന്നത് അറേബ്യൻ ജനത "
        "പണ്ടുകാലം മുതൽ മധ്യകാലഘട്ടം വരെ "
        "യുദ്ധങ്ങൾക്കായി ഉപയോഗിച്ചിരുന്ന "
        "യുദ്ധക്കുതിരകളെയാണ് (ഈ പദം "
        "സ്ത്രീലിംഗത്തിൽ വരാൻ കാരണം, പൊതുവെ "
        "അവർ ആൺകുതിരകളേക്കാൾ പെൺകുതിരകളെയാണ് "
        "മുൻഗണന നൽകിയിരുന്നത് എന്നതിനാലാണ്). "
        "എന്നാൽ പരമ്പരാഗതമായ വിശദീകരണം "
        "അടിസ്ഥാനപ്പെടുത്തിയിരിക്കുന്നത് "
        "\"കുതിരപ്പടയാളികൾ\" ഇവിടെ ദൈവത്തിന്റെ "
        "മാർഗ്ഗത്തിലുള്ള വിശ്വാസികളുടെ "
        "പോരാട്ടത്തെ (ജിഹാദ്) "
        "പ്രതീകവൽക്കരിക്കുന്നു എന്നും അതിനാൽ "
        "അത് വളരെയധികം പ്രശംസനീയമായ "
        "ഒന്നാണെന്നുമുള്ള അനുമാനത്തെയാണ്; "
        "എങ്കിലും അത്തരം ഒരു നല്ല "
        "പ്രതീകാത്മകതയും ആറാമത്തെ വചനം മുതൽ "
        "പ്രകടിപ്പിക്കുന്ന അപലപനവും തമ്മിലുള്ള "
        "വൈരുദ്ധ്യം അത് ഒട്ടും "
        "കണക്കിലെടുക്കുന്നില്ല, ഈ സൂറത്തിന്റെ "
        "രണ്ട് ഭാഗങ്ങൾ തമ്മിൽ യാതൊരു "
        "യുക്തിസഹമായ ബന്ധവും അത്തരം ഒരു "
        "പരമ്പരാഗത വ്യാഖ്യാനം നൽകുന്നില്ല "
        "എന്ന കാര്യം പറയേണ്ടതില്ലല്ലോ. "
        "എന്നാൽ അത്തരമൊരു ബന്ധം "
        "നിലനിൽക്കേണ്ടതുണ്ട് എന്നതിനാലും, 6 "
        "മുതൽ 11 വരെയുള്ള വചനങ്ങൾ "
        "നിസ്സംശയമായും അപലപിക്കുന്നവയായതിനാലും, "
        "ആദ്യത്തെ അഞ്ച് വചനങ്ങൾക്കും അതേ — "
        "അല്ലെങ്കിൽ കുറഞ്ഞപക്ഷം സമാനമായ — "
        "സ്വഭാവമാണുള്ളതെന്ന് നാം നിഗമനം "
        "ചെയ്യണം. \"കുതിരപ്പടയാളികൾ\" എന്ന "
        "പ്രതീകാത്മകത ഇവിടെ പ്രശംസനീയമായ "
        "അർത്ഥത്തിലാണ് ഉപയോഗിച്ചിരിക്കുന്നത് "
        "എന്ന മുൻവിധിയിൽ നിന്ന് നാം "
        "മാറുമ്പോൾ തന്നെ ഈ സ്വഭാവം "
        "പെട്ടെന്ന് വ്യക്തമാകും. വാസ്തവത്തിൽ, "
        "ഇതിന്റെ വിപരീതമാണ് സത്യം. യാതൊരു "
        "സംശയവുമില്ലാതെ, \"കുതിരകൾ\" "
        "സൂചിപ്പിക്കുന്നത് വഴിപിഴച്ച "
        "മനുഷ്യന്റെ ആത്മാവിനെ അല്ലെങ്കിൽ "
        "സ്വയത്തെയാണ് — യാതൊരു ആത്മീയ "
        "മാർഗ്ഗദർശനവുമില്ലാത്ത, എല്ലാത്തരം "
        "തെറ്റായതും സ്വാർത്ഥവുമായ "
        "ആഗ്രഹങ്ങളാൽ വേട്ടയാടപ്പെടുന്നതും "
        "നിയന്ത്രിക്കപ്പെടുന്നതുമായ ഒരു "
        "ആത്മാവ്; മനസ്സാക്ഷിയാലോ യുക്തിയാലോ "
        "തടയാനാകാതെ, ആശയക്കുഴപ്പമുണ്ടാക്കുന്നതും "
        "പ്രലോഭിപ്പിക്കുന്നതുമായ "
        "ആഗ്രഹങ്ങളുടെ പൊടിപടലങ്ങളാൽ കണ്ണ് "
        "കാണാതെ ഭ്രാന്തമായി മുന്നോട്ട് "
        "കുതിക്കുന്നതും, "
        "പരിഹരിക്കാനാകാത്ത "
        "സാഹചര്യങ്ങളിലേക്ക് "
        "ഇരച്ചുകയറുന്നതും, അങ്ങനെ സ്വന്തം "
        "ആത്മീയ തകർച്ചയിലേക്ക് "
        "എത്തിച്ചേരുന്നതുമായ ഒന്നാണത്."
    ),
    3: (
        "അതായത്, ഭ്രാന്തമായി ഇരച്ചുകയറുന്ന "
        "കുതിരപ്പടയാളികളാൽ "
        "പ്രതീകവൽക്കരിക്കപ്പെട്ട തന്റെ "
        "ആഗ്രഹങ്ങൾക്ക് അവൻ എപ്പോഴൊക്കെ "
        "കീഴ്‌പെടുന്നുവോ, അപ്പോഴൊക്കെ അവൻ "
        "ദൈവത്തെയും അവനോടുള്ള സ്വന്തം "
        "ഉത്തരവാദിത്തത്തെയും മറക്കുന്നു."
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
