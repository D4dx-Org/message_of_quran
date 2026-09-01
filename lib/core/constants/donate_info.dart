/// Copy and bank details for the Donate screen.
///
/// Kept here rather than in the database because it is fixed text that has to
/// stay identical on the app and the web, and because the account details
/// should not change without a code review.
class DonateInfo {
  DonateInfo._();

  static const String heading = 'Donate to www.quranasadmalayalam.in';

  static const String intro =
      'This website, based in India, is a free non-profit Islamic knowledge '
      "resource with Malayalam and English language translations of Muhammad "
      "Asad's Qur'an commentary, The Message of The Qur'an with links to "
      'several other Qur\'an and Hadeeth translations. The site sincerely '
      'attempts to provide and promote authentic knowledge base for the global '
      'audience by creating Islamic software and services - Apps for iOS, '
      'Android and the web - that are beneficial for not only the Muslims but '
      'also for anyone interested in learning Islam, its holy book, the Qur\'an '
      "and Prophet's traditions and history. This has a complete Qur'an text "
      "(Mus'haf) and an option (with links) for Qur'an audio with recitations "
      'of the most popular and globally recognized reciters like Sheikh Abdul '
      'Rahman Al-Sudais, Mishari Rashid Al-Afasy and Abdul Rahman Al-Ossi who '
      'are renowned Quranic reciters celebrated for their distinct, melodious, '
      'and emotionally moving styles that will have a profound impact on '
      'listeners.';

  static const String tagline =
      'One of the most useful Islamic knowledge resource.';

  /// Suggested amounts, shown as a hint for the transfer. Rupees only — the
  /// account is an Indian one and everything here settles in INR.
  static const List<String> suggestedAmounts = [
    '₹100',
    '₹200',
    '₹500',
    '₹1,000',
  ];

  static const String amountsNote =
      'Any amount is welcome — these are only suggestions.';

  static const String bankHeading = 'Donate by direct bank transfer';

  static const String bankNote =
      'Your contribution helps cover the expenses for maintaining and '
      'upgrading this service, and keeps it free of cost and free of ads.';

  /// Label/value pairs, rendered in order. Values are selectable so an account
  /// number or code can be copied straight out of the page.
  static const List<(String, String)> bankDetails = [
    ('Account Name', 'Saleem K C'),
    ('Account Number', '10618545316'),
    ('Bank', 'State Bank of India'),
    ('Branch', 'West Hill, Kozhikode - 673011, Kerala, India'),
    ('IFSC Code', 'SBIN0070857 (for NEFT/RTGS)'),
    ('SWIFT Code', 'SBININBB392'),
  ];
}
