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

  /// Arabic block (quran_asad.sqlite → arabic_ayahs)
  static const String arabicBlockTable = "arabic_ayahs";
  static const String arabicBlockText = "data_arabic";
  static const String verseFrom = "verse_from";
  static const String verseTo = "verse_to";

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
  static const int quranAsadDbVersion = 4;

  // ─── Table names (quran_asad.sqlite) ───
  static const String asadSurahsTable = "surahs";
  static const String asadVersesTable = "verses";
  static const String asadFootnotesTable = "footnotes";

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

  // ─── quranayas (quran_asad.sqlite → quranayas) ───
  static const String quranAyasTable = "quranayas";
  static const String quranAyasContAyaNo = "contiayano";
  static const String quranAyasSurahId = "suraid";
  static const String quranAyasAyahId = "ayaid";
  static const String quranAyasAyahText = "AyaHText";
}
