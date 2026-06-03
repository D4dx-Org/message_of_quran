import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/constants/app_constants.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';

class PlatformHelper {
  PlatformHelper._();

  static bool get isWeb => kIsWeb;

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static Uri get publicAppUri {
    if (isAndroid) {
      return Uri.parse(AppConstants.androidStoreUrl);
    }
    return Uri.parse(ApiConstants.d4dxWebsiteUrl);
  }

  static String get publicAppUrl => publicAppUri.toString();
}