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

  /// Suggested amounts in rupees — the account is an Indian one and
  /// everything here settles in INR.
  static const List<int> suggestedAmounts = [100, 200, 500, 1000];

  static String formatAmount(int rupees) {
    final digits = rupees.toString();
    if (digits.length <= 3) return '₹$digits';
    // Indian grouping: last three digits, then pairs.
    final head = digits.substring(0, digits.length - 3);
    return '₹$head,${digits.substring(digits.length - 3)}';
  }

  /// UPI VPA that the amount buttons pay into. While this is empty the
  /// buttons fall back to PayPal, so a wrong or guessed id can never collect
  /// money.
  static const String upiId = '';

  static const String upiPayeeName = 'Saleem K C';

  /// PayPal with the amount filled in. The currency is stated explicitly:
  /// `paypal.me/<name>/100` renders in the *sender's* currency, so a rupee
  /// button could otherwise present a donor with 100 dollars.
  static String paypalUrlFor(int rupees) => '$paypalUrl/${rupees}INR';

  /// UPI deep link. Handled by any UPI app on the device; desktop browsers
  /// have nothing registered for the scheme, which is why the amount buttons
  /// only take this route when [upiId] is set and the platform can open it.
  static String upiUrlFor(int rupees) {
    final params = <String, String>{
      'pa': upiId,
      'pn': upiPayeeName,
      'am': rupees.toString(),
      'cu': 'INR',
      'tn': 'Donation to quranasadmalayalam.in',
    };
    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return 'upi://pay?$query';
  }

  static const String amountsNote =
      'Any amount is welcome — these are only suggestions.';

  static const String paypalUrl = 'https://paypal.me/saleemkc';

  static const String paypalLabel = 'Donate with PayPal';

  /// The PayPal button carries an amount because paypal.me shows only a bare
  /// "Send" without one, leaving the donor nothing to type into. With an
  /// amount the page opens on an editable field they can change before
  /// sending, so this is a starting point rather than a fixed price.
  static const int paypalDefaultAmount = 100;

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
