import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/common_email/models/common_email_requests.dart';

class CommonEmailApi {
  CommonEmailApi({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<void> sendFeedback(FeedbackRequest request) {
    return _post(
      url: ApiConstants.feedbackUrl,
      body: request.toJson(),
      headers: _feedbackHeaders,
      fallbackErrorMessage: 'Unable to send feedback right now.',
    );
  }

  Future<void> sendFeatureRequest(FeatureRequestSubmission request) {
    return _post(
      url: ApiConstants.featureRequestUrl,
      body: request.toJson(),
      fallbackErrorMessage: 'Unable to send feature request right now.',
    );
  }

  Future<void> _post({
    required String url,
    required Map<String, dynamic> body,
    Map<String, String> headers = const {},
    required String fallbackErrorMessage,
  }) async {
    final ownsClient = _client == null;
    final client = _client ?? http.Client();

    try {
      final response = await client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              ...headers,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return;
      }

      throw CommonEmailApiException(
        _readErrorMessage(response.body) ?? fallbackErrorMessage,
      );
    } on TimeoutException {
      throw const CommonEmailApiException(
        'The request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const CommonEmailApiException(
        'No internet connection. Please try again.',
      );
    } on CommonEmailApiException {
      rethrow;
    } catch (_) {
      throw CommonEmailApiException(fallbackErrorMessage);
    } finally {
      if (ownsClient) {
        client.close();
      }
    }
  }

  Map<String, String> get _feedbackHeaders {
    return <String, String>{
      'x-app-theme-primary': AppTheme.appThemePrimaryHex,
      'x-app-theme-secondary': AppTheme.appThemeSecondaryHex,
      'x-app-theme-on-primary': AppTheme.appBarForegroundHex,
    };
  }

  String? _readErrorMessage(String responseBody) {
    if (responseBody.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        final message = decoded['message'];
        if (error is String && error.trim().isNotEmpty) {
          return error;
        }
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
    } catch (_) {
      return null;
    }

    return null;
  }
}
