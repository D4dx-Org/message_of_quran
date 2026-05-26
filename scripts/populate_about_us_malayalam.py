"""
Adds an 'about_us' table to quran_asad_malayalam_nw.db and inserts the
Malayalam About Us page content.
"""

import sqlite3
import os

DB_PATH = os.path.join(
    os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad_malayalam_nw.db'
)

CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS about_us (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    description TEXT,
    signed_by TEXT
);
"""

TITLE = "ഞങ്ങളെക്കുറിച്ച്"

DESCRIPTION = (
    "പരിശുദ്ധ ഖുർആന്റെ ശാശ്വത സന്ദേശം ലോകമെമ്പാടുമുള്ള ആളുകൾക്ക് കൂടുതൽ "
    "എളുപ്പത്തിലും അർത്ഥവത്തായും ലഭ്യമാക്കുക എന്ന ലക്ഷ്യത്തോടെ D4DX INNOVATIONS LLP "
    "വികസിപ്പിച്ച സമഗ്ര ഡിജിറ്റൽ പ്ലാറ്റ്ഫോമാണ് മുഹമ്മദ് അസദിന്റെ The Message of "
    "The Qur'an. iOS, Android, Web പ്ലാറ്റ്ഫോമുകളിൽ ലഭ്യമായ ഈ സംരംഭം ഖുർആൻ "
    "വായിക്കാനും മനസ്സിലാക്കാനും അതിലെ സന്ദേശങ്ങളെ ജീവിതത്തിൽ പ്രാവർത്തികമാക്കാനും "
    "സഹായിക്കുന്ന ഉപയോക്തൃ സൗഹൃദ സംവിധാനമാണ്.\n\n"
    "ആധുനിക സാങ്കേതികവിദ്യയും ആധികാരിക ഇസ്\u200cലാമിക ഉള്ളടക്കവും സംയോജിപ്പിച്ച് "
    "വിവിധ ഡിവൈസിലൂടെ സുഗമമായ അനുഭവം നൽകുക എന്നതാണ് ഈ പ്ലാറ്റ്ഫോമിലൂടെ ലക്ഷ്യം "
    "വെയ്ക്കുന്നത്. ഖുർആന്റെ ആശയങ്ങൾ പഠിക്കാനും അതിന്റെ അർത്ഥങ്ങളും "
    "വിശദീകരണങ്ങളും മനസ്സിലാക്കാനും അല്ലാഹുവിന്റെ ഗ്രന്ഥവുമായി കൂടുതൽ അടുത്ത "
    "ബന്ധം സ്ഥാപിക്കാനും ഇതിലൂടെ സാധ്യമാകും.\n\n"
    "ലളിതത്വം, ഉപയോഗ സൗകര്യം, ആത്മീയ വളർച്ച എന്നിവ മുൻനിർത്തി രൂപകൽപ്പന ചെയ്ത "
    "ഈ പ്ലാറ്റ്ഫോം പഠനത്തിനും ചിന്തനത്തിനും വ്യക്തിത്വ വളർച്ചയ്ക്കും ഒരു ആത്മീയ "
    "കൂട്ടാളിയായി പ്രവർത്തിക്കുമെന്നതിൽ സംശയമില്ല. ഡിജിറ്റൽ സാങ്കേതികവിദ്യയുടെ "
    "സാധ്യതകൾ ഉപയോഗപ്പെടുത്തി ഗുണകരമായ അറിവുകൾ കൂടുതൽ ആളുകളിലേക്ക് എത്തിക്കുക "
    "എന്നതാണ് D4DX INNOVATIONS LLP ഇത്തരം സംരംഭങ്ങളിലൂടെ ആ\u200bഗ്രഹിക്കുന്നത്."
)

SIGNED_BY = "D4DX INNOVATIONS LLP"


def main():
    db_path = os.path.normpath(DB_PATH)
    print(f"Opening database: {db_path}")

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Drop existing table if any (for idempotent re-runs)
    cursor.execute("DROP TABLE IF EXISTS about_us")
    cursor.execute(CREATE_TABLE_SQL)

    cursor.execute(
        "INSERT INTO about_us (title, description, signed_by) VALUES (?, ?, ?)",
        (TITLE, DESCRIPTION, SIGNED_BY),
    )

    conn.commit()

    # Verify
    cursor.execute("SELECT * FROM about_us")
    rows = cursor.fetchall()
    print(f"Inserted {len(rows)} row(s) into about_us table.")
    for row in rows:
        print(f"  id={row[0]}, title={row[1]}, signed_by={row[3]}")

    conn.close()
    print("Done.")


if __name__ == "__main__":
    main()
