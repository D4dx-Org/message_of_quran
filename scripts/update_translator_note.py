"""
Update translator_note table to match the printed book version.
"""
import sqlite3

DB_PATH = "assets/db/quran_asad_malayalam.db"

# The old ending section (from DB - adapted for digital)
OLD_ENDING = (
    "ഈ പരിഭാഷ പൂർത്തിയാക്കുന്നതിലും രണ്ടാം പാതിയുടെ അടിക്കുറിപ്പുകൾ വിവർത്തനം ചെയ്യുന്നതിലും  "
    "എന്നെ സഹായിച്ച ഡോ.  എൻ.കെ. അയ്യൂബ് റഹ്\u200cമാനോട്  അതിരറ്റ നന്ദിയുണ്ട്. "
    "സംശോധനം നിർവഹിച്ച മുഹമ്മദ് ശമീം, ദിൽറുബാ ശബ്നം എന്നിവരോടും "
    "അക്ഷരത്തെറ്റുകൾ തീർക്കാൻ സഹായിച്ച യഹ്\u2018യയോടും എനിക്കുള്ള നന്ദി സീമാതീതമാണ്\u200c. "
    "ഈ ദൗത്യത്തിന് എന്നെ പ്രോൽസാഹിപ്പിക്കുകയും പിന്തുണക്കുകയും ചെയ്ത എന്റെ സഹധർമിണി ഷമീം, "
    "പ്രോൽസാഹനവുമായി എപ്പോഴും കൂടെ നിന്ന എന്റെ പ്രിയസുഹൃത്ത് കാനഡയിലെ ഫിറോസ് ഒസ്മാൻ "
    "അടക്കം ഏതാനും പേർ വേറെയുമുണ്ട്. അവരോടും ഞാൻ കടപ്പെട്ടിരിക്കുന്നു. "
    "പുതിയ കാലത്തിന്റെ ആവശ്യം കണക്കിലെടുത്താണ്\u200c വലിയ തുക ചെലവഴിച്ച് നാല്\u200c "
    "വാല്യങ്ങളിലായി അച്ചടിച്ച് പുറത്തിറക്കുന്നതിന്\u200c പകരം, "
    "ലോകത്തെല്ലായിടത്തുമുള്ള ആളുകൾക്ക് മൊബൈൽ ഫോൺ, ലാപ്ടോപ്, വെബ് തുടങ്ങിയവയിലൂടെ "
    "എല്ലാ കാലത്തും സൗജന്യമായി ലഭ്യമാവുന്ന തരത്തിൽ ഡിജിറ്റൽ വേർഷൻ ആയി പ്രസിദ്ധീകരിക്കാം "
    "എന്ന് തീരുമാനിച്ചത്. ഇരുപതാം നൂറ്റാണ്ടിനോടൊപ്പം സഹയാത്ര ചെയ്ത മുഹമ്മദ് അസദ് എന്ന "
    "മഹാമനീഷിയുടെ മൗലിക ചിന്തകൾ മലയാളികളുടെ ജ്ഞാനാന്വേഷണങ്ങൾക്ക് നവോന്മേഷം "
    "നൽകുമാറാകട്ടെയെന്നും മലയാളവായനക്കാർ സസന്തോഷം ഇത് സ്വീകരിക്കുമാറാകട്ടെ "
    "എന്നുമാണ് പ്രാർത്ഥന.  \n"
)

# The new ending section (from the book - printed version)
NEW_ENDING = (
    "ഈ പരിഭാഷ പൂർത്തിയാക്കുന്നതിൽ എന്നെ സഹായിച്ച എൻ.കെ. അയ്യൂബ് റഹ്\u200cമാനോടും "
    "അടിക്കുറിപ്പുകളുടെ ചില ഭാഗങ്ങൾ പൂർത്തിയാക്കുന്നതിൽ സഹായിച്ച കെ.എസ്. ഷമീരിനോടും "
    "അതിരറ്റ നന്ദിയുണ്ട്. ഈ ദൗത്യത്തിന് എന്നെ പ്രോൽസാഹിപ്പിക്കുകയും പിന്തുണക്കുകയും "
    "ചെയ്ത എന്റെ സഹധർമിണി ഷമീം അടക്കം ഏതാനും പേർ വേറെയുമുണ്ട്. അവരോടും ഞാൻ "
    "കടപ്പെട്ടിരിക്കുന്നു. ഇത് പ്രസിദ്ധീകരിക്കാൻ മുമ്പോട്ട് വന്ന പ്രസാധകർക്കുള്ളതാണ് "
    "ഏറ്റവും വലിയ കൃതജ്ഞത. ഇരുപതാം നൂറ്റാണ്ടിനോടൊപ്പം സഹയാത്ര ചെയ്ത മുഹമ്മദ് അസദ് "
    "എന്ന മഹാമനീഷിയുടെ മൗലിക ചിന്തകൾ മലയാളികളുടെ ജ്ഞാനാന്വേഷണങ്ങൾക്ക് നവോന്മേഷം "
    "നൽകുമാറാകട്ടെയെന്നും മലയാളവായനക്കാർ സസന്തോഷം ഇത് സ്വീകരിക്കുമാറാകട്ടെ "
    "എന്നുമാണ് പ്രാർത്ഥന.\n"
)


def main():
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    # Get current content
    c.execute("SELECT content FROM translator_note WHERE id = 1")
    row = c.fetchone()
    if not row:
        print("ERROR: No row found with id=1")
        conn.close()
        return

    content = row[0]

    # Find the old ending
    search_key = "ഈ പരിഭാഷ പൂർത്തിയാക്കുന്നതിലും രണ്ടാം"
    idx = content.find(search_key)
    if idx == -1:
        print("ERROR: Could not find the old ending section in content")
        conn.close()
        return

    # Replace: keep everything before the old ending, append new ending
    new_content = content[:idx] + NEW_ENDING

    # Update the row
    c.execute(
        "UPDATE translator_note SET content = ?, date = ? WHERE id = 1",
        (new_content, "01.12.2022"),
    )
    conn.commit()
    print(f"SUCCESS: Updated translator_note content and date.")
    print(f"  Old ending length: {len(content) - idx}")
    print(f"  New ending length: {len(NEW_ENDING)}")
    print(f"  Date changed to: 01.12.2022")

    # Verify
    c.execute("SELECT date FROM translator_note WHERE id = 1")
    print(f"  Verified date: {c.fetchone()[0]}")

    conn.close()


if __name__ == "__main__":
    main()
