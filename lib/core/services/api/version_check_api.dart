import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';

class VersionCheckApi {
  static Future<dynamic> checkUpdate() async {
    final client = http.Client();
    try {
      final response = await client
          .get(Uri.parse(ApiConstants.updateCheckUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return "Something went Wrong";
    } catch (e) {
      return "error while checking : $e";
    } finally {
      client.close();
    }
  }
}
