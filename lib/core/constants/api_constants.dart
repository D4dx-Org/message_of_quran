class ApiConstants {
  /// Base URL of the MOQ backend that serves the Quran content.
  /// Override at build time: `--dart-define=MOQ_API_BASE_URL=https://…`
  static const String moqApiBaseUrl = String.fromEnvironment(
    'MOQ_API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  /// Large photos are served from DigitalOcean Spaces instead of being bundled.
  /// Small thumbnails stay in the app so a blurred preview shows offline.
  static const String imageCdnBaseUrl =
      'https://d4dx-storage.blr1.cdn.digitaloceanspaces.com/Asad/images';

  static const String everyAyahAudioBaseUrl = 'https://everyayah.com/data';
  static const String bookplusUrl = 'https://www.bookplus.co.in';
  static const String d4dxWebsiteUrl = 'https://d4dx.co/';
  static const String privacyPolicyUrl = 'https://d4dx.co/privacy-policy/';
  static const String commonEmailBaseUrl = 'https://cenloginbackend.d4dx.co';
  static const String feedbackUrl =
      '$commonEmailBaseUrl/api/quran-asad-email/send-feedback';
  static const String featureRequestUrl = '$commonEmailBaseUrl/feature-request';
  static const String updateCheckUrl =
      "";
}
