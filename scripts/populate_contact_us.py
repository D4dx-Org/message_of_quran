"""
Adds a 'contact_us' table to quran_asad_malayalam.db and inserts the
Malayalam contact page content.
"""

import sqlite3
import os

DB_PATH = os.path.join(
    os.path.dirname(__file__), '..', 'assets', 'db', 'quran_asad_malayalam.db'
)

CREATE_TABLE_SQL = """
CREATE TABLE IF NOT EXISTS contact_us (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT,
    description TEXT,
    address TEXT,
    email TEXT,
    mobile TEXT
);
"""

TITLE = "Contact Us"

DESCRIPTION = (
    "www.quranasadmalayalam.in എന്ന വെബ്\u200cസൈറ്റ്, മുഹമ്മദ് അസദിന്റെ ഖുർആൻ വ്യാഖ്യാനത്തിന്റെ "
    "- ഖുർആന്റെ സന്ദേശം - മലയാളം, ഇംഗ്ലീഷ് ഭാഷാ വിവർത്തനങ്ങളും മറ്റ് നിരവധി ഖുർആൻ, "
    "ഹദീസ് വിവർത്തനങ്ങളിലേക്കുള്ള ലിങ്കുകളും ഉൾക്കൊള്ളുന്ന ലാഭേച്ഛയില്ലാത്ത തികച്ചും "
    "സൗജന്യമായ ഒരു ഇസ്ലാമിക വിജ്ഞാന സ്രോതസ്സാണ്. മുസ്ലിംകൾക്ക് മാത്രമല്ല, "
    "ഇസ്\u200cലാമിനെയും അതിന്റെ വിശുദ്ധ ഗ്രന്ഥത്തെയും ഖുർആനെയും പ്രവാചക പാരമ്പര്യങ്ങളെയും "
    "ചരിത്രത്തെയും കുറിച്ച് പഠിക്കാൻ താൽപ്പര്യമുള്ള ഏതൊരാൾക്കും പ്രയോജനകരമായ ഇസ്ലാമിക "
    "സോഫ്റ്റ്\u200cവെയറും സേവനങ്ങളും - iOS, Android, വെബ് എന്നിവയ്\u200cക്കായുള്ള ആപ്പുകൾ - "
    "സൃഷ്ടിച്ചുകൊണ്ട് ലോകത്തെല്ലായിടത്തുമുള്ളവർക്ക് ആധികാരികമായ വൈജ്ഞാനികാടിത്തറ "
    "നൽകാനും പ്രോത്സാഹിപ്പിക്കാനും സൈറ്റ് ആത്മാർത്ഥമായി ശ്രമിക്കുന്നു. ഇതിൽ ഒരു "
    "സമ്പൂർണ്ണ ഖുർആൻ പാഠവും (മുസ്ഹഫ്), ആഗോളതലത്തിൽ അംഗീകരിക്കപ്പെട്ട, ഹൃദ്യമായി "
    "ഖുർആൻ പാരായണം ചെയ്യുന്ന ഏറ്റവും ജനപ്രിയരായ ഷെയ്ഖ് അബ്ദുൽ റഹ്മാൻ അൽ-സുദൈസ്, "
    "അബ്ദുൾ റഹ്മാൻ അൽ-ഒസ്സി തുടങ്ങിയവരുടെ പാരായണങ്ങളുള്ള ഖുർആൻ ഓഡിയോയും "
    "ഉൾപ്പെടുന്നു. ശ്രോതാക്കളിൽ ആഴത്തിലുള്ള സ്വാധീനം ചെലുത്തുന്ന, വ്യത്യസ്തവും "
    "വൈകാരികവുമായ ശൈലികൾക്ക് പേരുകേട്ട ഖുർആൻ ഖാരിഉകളാണ്\u200c ഇവർ. സൈറ്റും ആപ്പുകളും "
    "മെച്ചപ്പെടുത്താനും പുതിയതും ഉപയോഗപ്രദവുമായ സവിശേഷതകൾ ഉപയോഗിച്ച് അതിന്റെ "
    "ഉള്ളടക്കങ്ങൾ വികസിപ്പിക്കാനും ഞങ്ങൾ നിരന്തരം ശ്രമിക്കുന്നതാണ്\u200c. താങ്കളുടെ "
    "വിലയേറിയ അഭിപ്രായങ്ങൾ CONTACT US എന്നത് ക്ലിക്ക് ചെയ്ത് ഞങ്ങളെ അറിയിച്ചാൽ "
    "വലിയ ഉപകാരമാവും. അറിയാതെ ഇതിൽ വന്നു പോയ തെറ്റുകൾ താങ്കളുടെ ശ്രദ്ധയിൽ "
    "പെട്ടെങ്കിൽ അത് ഞങ്ങളെ അറിയിക്കാനും ഈ മാർഗം ഉപയോഗിക്കാം.\n\n"
    "സത്യാന്വേഷികൾക്ക് ഈ സംരംഭം പ്രയോജനകരമാണെന്ന് താങ്കൾ കരുതുന്നുവെങ്കിൽ, "
    "ദയവായി സംഭാവന നൽകി സഹായിക്കുക. തലമുറകളോളം സൗജന്യമായും പരസ്യരഹിതമായും "
    "ലഭ്യമാവുന്ന ഈ മഹത്തായ ഉദ്യമം നിലച്ചു പോവാതെ നിലനിർത്തുന്നതിൽ താങ്കളുടെ "
    "സഹായം വലിയൊരു പങ്ക് വഹിക്കുമെന്ന് ഉറപ്പാണ്\u200c."
)

ADDRESS = "Shadan, Check Post Road, Puthiyangadi, Kozhikode - 673021. Kerala. India."
EMAIL = "kcsaleem07@gmail.com"
MOBILE = "+91 8714983065"


def main():
    db_path = os.path.normpath(DB_PATH)
    print(f"Opening database: {db_path}")

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()

    # Drop existing table if any (for idempotent re-runs)
    cursor.execute("DROP TABLE IF EXISTS contact_us")
    cursor.execute(CREATE_TABLE_SQL)

    cursor.execute(
        "INSERT INTO contact_us (title, description, address, email, mobile) VALUES (?, ?, ?, ?, ?)",
        (TITLE, DESCRIPTION, ADDRESS, EMAIL, MOBILE),
    )

    conn.commit()

    # Verify
    cursor.execute("SELECT * FROM contact_us")
    rows = cursor.fetchall()
    print(f"Inserted {len(rows)} row(s) into contact_us table.")
    for row in rows:
        print(f"  id={row[0]}, title={row[1][:30]}..., address={row[3]}")

    conn.close()
    print("Done.")


if __name__ == "__main__":
    main()
