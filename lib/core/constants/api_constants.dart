class ApiConstants {
  static const String everyAyahAudioBaseUrl = 'https://everyayah.com/data';
  static const String bookplusUrl = 'https://www.bookplus.co.in';
  static const String d4dxWebsiteUrl = 'https://d4dx.co/';
  static const String privacyPolicyUrl = 'https://d4dx.co/privacy-policy/';
  static const String commonEmailBaseUrl = 'https://cenloginbackend.d4dx.co';
  static const String quranAsadEmailApiKey = String.fromEnvironment(
    'QURAN_ASAD_EMAIL_API_KEY',
  );
  static const String feedbackUrl =
      '$commonEmailBaseUrl/api/quran-asad-email/send-feedback';
  static const String featureRequestUrl = '$commonEmailBaseUrl/feature-request';
  static const String updateCheckUrl =
      "https://directus.d4dx.co/items/quran_app_force_update";
}
