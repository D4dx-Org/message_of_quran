import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';

class PlatformHelper {
  PlatformHelper._();

  static const String _androidStoreUrl =
      'https://play.google.com/store/apps/details?id=com.d4dx.quranasadmalayalam';

  static bool get isWeb => kIsWeb;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static Uri get publicAppUri {
    if (isAndroid) {
      return Uri.parse(_androidStoreUrl);
    }
    return Uri.parse(ApiConstants.d4dxWebsiteUrl);
  }

  static String get publicAppUrl => publicAppUri.toString();
}