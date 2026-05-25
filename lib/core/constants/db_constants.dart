class DbConstants {
  DbConstants._internal();
  factory DbConstants() => _instance;
  static final DbConstants _instance = DbConstants._internal();

  /// Database names
  static const String userDbName = "user_data.db";
  static const String dbLocation = "assets/db";

  // ─── Table names ───
  static const String surasTable = "suras";
  static const String translationsTable = "translations";
  static const String interpretationsTable = "interpretations";
  static const String aboutUsTableName = "about_us";
  static const String contactTableName = "contact_us";
  static const String authorTableName = "authors";
  static const String helpTableName = "help";
  static const String bookmarksTableName = "bookmarks";

  // ─── Common fields ───
  static const String id = "id";
  static const String createdBy = "created_by";
  static const String createdByRole = "created_by_role";
  static const String isVerified = "is_verified";

  // ─── Suras ───
  static const String suraNumber = "sura_number";
  static const String suraName = "name";
  static const String suraArabicName = "arabic_name";
  static const String suraDescription = "description";
  static const String suraAyathCount = "ayath_count";
  static const String suraPlace = "place";

  // ─── Translations ───
  static const String translationText = "translation_text";
  static const String ayaRangeStart = "aya_range_start";
  static const String ayaRangeEnd = "aya_range_end";
  static const String language = "language";

  // ─── Interpretations ───
  static const String interpretationText = "interpretation_text";
  static const String interpretationNumber = "interpretation_number";
  // Also uses: suraNumber, ayaRangeStart, ayaRangeEnd, language

  // ─── Juz & Hizb (quran_asad.sqlite) ───
  static const String juzzTable = "juzzs";
  static const String hizbTable = "hizbs";
  static const String customId = "custom_id";
  static const String verseNo = "verse_no";

  // ─── chapter_no used across tables ───
  static const String chapterNo = "chapter_no";

  /// Tajweed words (quran_asad.sqlite → tajweed_words)
  static const String tajweedTable = "tajweed_words";
  static const String tajweedSurahNo = "surah_no";
  static const String tajweedAyahNo = "ayah_no";
  static const String tajweedWordPos = "word_pos";
  static const String tajweedWordText = "word_text";
  static const String tajweedImageUrl = "image_url";

  /// About us
  static const String aboutTitle = "title";
  static const String aboutDescription = "description";
  static const String aboutCreatedBy = "created_by";
  static const String aboutCreatedByRole = "created_by_role";
  static const String aboutIsVerified = "is_verified";

  /// Contact us
  static const String contactMobile = "mobile";
  static const String contactWhatsapp = "whatsapp";
  static const String contactEmail = "email";
  static const String contactAddress = "address";
  static const String contactRemarks = "remarks";
  static const String contactCreatedBy = "created_by";
  static const String contactCreatedByRole = "created_by_role";
  static const String contactIsVerified = "is_verified";

  ///Authors
  static const String authorName = "html_content";
  static const String authorCreatedBy = "created_by";
  static const String authorCreatedByRole = "created_by_role";
  static const String authorIsVerified = "is_verified";
  static const String authorId = "id";

  /// Help
  static const String helpId = "id";
  static const String helpTitle = "title";
  static const String helpDescription = "description";
  static const String helpSortOrder = "sort_order";
  static const String helpCreatedBy = "created_by";
  static const String helpCreatedByRole = "created_by_role";
  static const String helpIsVerified = "is_verified";

  /// Bookmarks (user_data.db)
  static const String bookmarkId = "id";
  static const String bookmarkSurahNumber = "surah_number";
  static const String bookmarkAyahId = "ayah_id";
  static const String bookmarkSurahName = "surah_name";
  static const String bookmarkAyaText = "aya_text";
  static const String bookmarkSurahArabicName = "surah_arabic_name";
  static const String bookmarkSurahArabicNumber = "surah_arabic_number";
  static const String bookmarkLabel = "label";
  static const String bookmarkNavigationTarget = "navigation_target";

  /// Preface / Surah description (quran_asad.sqlite → prefaces)
  static const String prefaceTable = "prefaces";
  static const String prefaceId = "custom_id";
  static const String prefaceSubTitle = "preface_sub_title";
  static const String prefaceText = "preface_text";
  static const String prefaceSuraId = "sura_id";

  // ═══════════════════════════════════════════════════════════════════════════
  // quran_asad.sqlite database
  // ═══════════════════════════════════════════════════════════════════════════
  static const String quranAsadDbName = "quran_asad.sqlite";
  static const String quranAsadDbVersionKey = 'quran_asad_db_version';
  static const int quranAsadDbVersion = 11;

  // ─── Table names (quran_asad.sqlite) ───
  static const String asadSurahsTable = "surahs";
  static const String asadVersesTable = "verses";
  static const String asadFootnotesTable = "footnotes";
  static const String asadAuthorsTable = "authors";
  static const String asadTranslatorTable = "translator";
  static const String worksOfReferenceTable = "worksofreference";

  // ─── surahs columns (quran_asad.sqlite → surahs) ───
  static const String asadSurahNumber = "number";
  static const String asadSurahOrdinalLabel = "ordinal_label";
  static const String asadSurahName = "name";
  static const String asadSurahTranslation = "translation";
  static const String asadSurahPeriod = "period";
  static const String asadSurahHasBismillah = "has_bismillah";
  static const String asadSurahIntroduction = "introduction";
  static const String asadSurahMalayalamName = "malayalam_name";

  // ─── verses columns (quran_asad.sqlite → verses) ───
  static const String asadVerseId = "id";
  static const String asadVerseSurahNumber = "surah_number";
  static const String asadVerseNumber = "verse_number";
  static const String asadVerseText = "text";

  // ─── footnotes columns (quran_asad.sqlite → footnotes) ───
  static const String asadFootnoteId = "id";
  static const String asadFootnoteSurahNumber = "surah_number";
  static const String asadFootnoteNumber = "footnote_number";
  static const String asadFootnoteText = "text";

  // ─── authors columns (quran_asad.sqlite → authors) ───
  static const String asadAuthorId = "id";
  static const String asadAuthorHtmlContent = "html_content";
  static const String asadAuthorCreatedBy = "created_by";
  static const String asadAuthorCreatedByRole = "created_by_role";
  static const String asadAuthorIsVerified = "is_verified";

  // ─── translator columns (quran_asad.sqlite → translator) ───
  static const String asadTranslatorId = "id";
  static const String asadTranslatorName = "name";
  static const String asadTranslatorRole = "role";
  static const String asadTranslatorBio = "bio";
  static const String asadTranslatorEmail = "email";
  static const String asadTranslatorAddress = "address";

  // ─── works of reference columns (quran_asad.sqlite → worksofreference) ───
  static const String worksOfReferenceId = "id";
  static const String worksOfReferenceHtmlContent = "html_content";
  static const String worksOfReferenceCreatedBy = "created_by";
  static const String worksOfReferenceCreatedByRole = "created_by_role";
  static const String worksOfReferenceIsVerified = "is_verified";

  // ─── quranayas (quran_asad.sqlite → quranayas) ───
  static const String quranAyasTable = "quranayas";
  static const String quranAyasContAyaNo = "contiayano";
  static const String quranAyasSurahId = "suraid";
  static const String quranAyasAyahId = "ayaid";
  static const String quranAyasAyahText = "AyaHText";

  // ─── malayalam_dummy_datas (quran_asad.sqlite → malayalam_dummy_datas) ───
  static const String malayalamDummyDatasTable = "malayalam_dummy_datas";
  static const String malayalamDummyId = "id";
  static const String malayalamDummySurahId = "surah_id";
  static const String malayalamDummyAyahId = "ayah_id";
  static const String malayalamDummyTranslation = "malayalam_translation";
  static const String malayalamDummyInterpretation = "malayalam_interpretation";
  static const String malayalamDummySurahIntroduction = "surah_introduction";

  // ─── appendices (quran_asad.sqlite → appendices) ───
  static const String appendicesTable = "appendices";
  static const String appendixNumber = "number";
  static const String appendixRomanNumeral = "roman_numeral";
  static const String appendixTitle = "title";
  static const String appendixBody = "body";
  static const String appendixPageStart = "page_start";
  static const String appendixPageEnd = "page_end";

  // ─── foreword (quran_asad.sqlite → foreword) ───
  static const String forewordTable = "foreword";
  static const String forewordId = "id";
  static const String forewordBody = "body";

  // ─── contact_us_content (quran_asad.sqlite → contact_us_content) ───
  static const String enContactUsTable = "contact_us_content";
  static const String enContactUsId = "id";
  static const String enContactUsTitle = "title";
  static const String enContactUsDescription = "description";
  static const String enContactUsAddress = "address";
  static const String enContactUsEmail = "email";
  static const String enContactUsMobile = "mobile";

  // ═══════════════════════════════════════════════════════════════════════════
  // quran_asad_malayalam_nw.db database
  // ═══════════════════════════════════════════════════════════════════════════
  static const String quranAsadMalayalamDbName = "quran_asad_malayalam_nw.db";
  static const String quranAsadMalayalamDbVersionKey =
      'quran_asad_malayalam_db_version';
  static const int quranAsadMalayalamDbVersion = 3;

  // ─── verses (quran_asad_malayalam.db → verses) ───
  static const String mlVersesTable = "verses";
  static const String mlVersesSurahId = "surah_id";
  static const String mlVersesVerseNumber = "verse_number";
  static const String mlVersesMalayalamTranslation = "malayalam_translation";

  // ─── Table names (quran_asad_malayalam.db) ───
  static const String mlAboutAuthorTable = "about_author";
  static const String mlTranslatorNoteTable = "translator_note";

  // ─── about_author columns (quran_asad_malayalam.db → about_author) ───
  static const String mlAboutAuthorId = "id";
  static const String mlAboutAuthorName = "name";
  static const String mlAboutAuthorRole = "role";
  static const String mlAboutAuthorBio = "bio";
  static const String mlAboutAuthorEmail = "email";
  static const String mlAboutAuthorMobile = "mobile";

  // ─── translator_note columns (quran_asad_malayalam.db → translator_note) ───
  static const String mlTranslatorNoteId = "id";
  static const String mlTranslatorNoteHeading = "heading";
  static const String mlTranslatorNoteContent = "content";
  static const String mlTranslatorNoteAuthor = "author";
  static const String mlTranslatorNoteDate = "date";

  // ─── preface (quran_asad_malayalam.db → preface) ───
  static const String mlPrefaceTable = "preface";
  static const String mlPrefaceId = "id";
  static const String mlPrefaceHeading = "heading";
  static const String mlPrefaceContent = "content";

  // ─── contact_us (quran_asad_malayalam.db → contact_us) ───
  static const String mlContactUsTable = "contact_us";
  static const String mlContactUsId = "id";
  static const String mlContactUsTitle = "title";
  static const String mlContactUsDescription = "description";
  static const String mlContactUsAddress = "address";
  static const String mlContactUsEmail = "email";
  static const String mlContactUsMobile = "mobile";

  // ─── footnotes (quran_asad_malayalam.db → footnotes) ───
  static const String mlFootnotesTable = "footnotes";
  static const String mlFootnoteId = "id";
  static const String mlFootnoteNumber = "footnote_number";
  static const String mlFootnoteContent = "content";

  // ─── surahs (quran_asad_malayalam.db → surahs) ───
  static const String mlSurahsTable = "surahs";
  static const String mlSurahId = "id";
  static const String mlSurahChapterNumber = "chapter_number";
  static const String mlSurahArabicName = "arabic_name";
  static const String mlSurahMalayalamName = "malayalam_name";
  static const String mlSurahEnglishTranslation = "english_translation";
  static const String mlSurahRevelationPeriod = "revelation_period";
  static const String mlSurahIntroduction = "introduction";

}
