import 'dart:io';

import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/constants/app_constants.dart';
import 'package:the_message_of_the_quran/core/services/api/version_check_api.dart';

class VersionCheckProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isUpdateNeeded = false;
  String message = "";
  Future<void> checkUpdate() async {
    isLoading = true;
    try {
      final result = await VersionCheckApi.checkUpdate();
      if (result is! Map<String, dynamic>) {
        isUpdateNeeded = false;
      } else {
        final data = result["data"];
        if (data is Map<String, dynamic>) {
          String appVersion =
              data[Platform.isAndroid ? "android_version" : "ios_version"] ??
                  '';
          message =
              data[Platform.isIOS ? "ios_content" : "android_content"] ?? '';
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
