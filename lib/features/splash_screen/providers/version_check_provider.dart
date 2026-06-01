import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/constants/app_constants.dart';
import 'package:the_message_of_the_quran/core/services/api/version_check_api.dart';
import 'package:the_message_of_the_quran/core/utils/platform_helper.dart';

class VersionCheckProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isUpdateNeeded = false;
  String message = "";
  Future<void> checkUpdate() async {
    isLoading = true;
    try {
      if (PlatformHelper.isWeb) {
        isUpdateNeeded = false;
        message = '';
        return;
      }

      final result = await VersionCheckApi.checkUpdate();
      if (result is! Map<String, dynamic>) {
        isUpdateNeeded = false;
      } else {
        final data = result["data"];
        if (data is Map<String, dynamic>) {
          final appVersion =
              data[PlatformHelper.isAndroid ? "android_version" : "ios_version"]
                  as String? ??
              '';
          message =
              data[PlatformHelper.isIOS ? "ios_content" : "android_content"]
                  as String? ??
              '';
          if (appVersion.isNotEmpty &&
              appVersion != AppConstants.appVersion) {
            isUpdateNeeded = true;
          }
        } else {
          isUpdateNeeded = false;
        }
      }
    } catch (e) {
      debugPrint('VersionCheckProvider: checkUpdate error – $e');
      isUpdateNeeded = false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
