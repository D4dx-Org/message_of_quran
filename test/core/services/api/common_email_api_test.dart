import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';
import 'package:the_message_of_the_quran/core/services/api/common_email_api.dart';
import 'package:the_message_of_the_quran/features/common_email/models/common_email_requests.dart';

void main() {
  group('CommonEmailApi', () {
    test(
      'sendFeedback posts the documented payload and API key header',
      () async {
        late Uri requestedUri;
        late Map<String, dynamic> requestBody;
        late Map<String, String> requestHeaders;

        final client = MockClient((request) async {
          requestedUri = request.url;
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          requestHeaders = request.headers;
          return http.Response('{"success": true}', 200);
        });

        final api = CommonEmailApi(
          client: client,
          feedbackApiKey: 'test-feedback-key',
        );

        await api.sendFeedback(
          const FeedbackRequest(
            name: 'Ali Rahman',
            email: 'ali@example.com',
            phone: '+919876543210',
            rating: FeedbackRating.good,
            message: 'Very useful app.',
            platform: 'android',
            source: 'the_message_of_the_quran',
            appName: 'The Message of The Quran',
          ),
        );

        expect(
          requestedUri.toString(),
          ApiConstants.feedbackUrl,
        );
        expect(requestHeaders['x-api-key'], 'test-feedback-key');
        expect(requestBody, {
          'name': 'Ali Rahman',
          'email': 'ali@example.com',
          'phone': '+919876543210',
          'rating': 'good',
          'message': 'Very useful app.',
          'platform': 'android',
          'source': 'the_message_of_the_quran',
          'appName': 'The Message of The Quran',
        });
      },
    );

    test(
      'sendFeatureRequest posts the documented payload to the public endpoint',
      () async {
        late Uri requestedUri;
        late Map<String, dynamic> requestBody;
        late Map<String, String> requestHeaders;

        final client = MockClient((request) async {
          requestedUri = request.url;
          requestBody = jsonDecode(request.body) as Map<String, dynamic>;
          requestHeaders = request.headers;
          return http.Response('{"success": true}', 200);
        });

        final api = CommonEmailApi(client: client);

        await api.sendFeatureRequest(
          const FeatureRequestSubmission(
            name: 'Fathima Zahra',
            email: 'fathima@example.com',
            phone: '+919876543210',
            title: 'Add bookmarking',
            description: 'Please add bookmarking for ayahs.',
            category: FeatureRequestCategory.content,
            targetPlatform: FeatureRequestTargetPlatform.mobile,
            platform: 'mobile',
            source: 'the_message_of_the_quran',
            appName: 'The Message of The Quran',
          ),
        );

        expect(
          requestedUri.toString(),
          ApiConstants.featureRequestUrl,
        );
        expect(requestHeaders.containsKey('x-api-key'), isFalse);
        expect(requestBody, {
          'name': 'Fathima Zahra',
          'email': 'fathima@example.com',
          'phone': '+919876543210',
          'featureTitle': 'Add bookmarking',
          'title': 'Add bookmarking',
          'featureDescription': 'Please add bookmarking for ayahs.',
          'description': 'Please add bookmarking for ayahs.',
          'category': 'content',
          'target_platform': 'mobile',
          'platform': 'mobile',
          'source': 'the_message_of_the_quran',
          'appName': 'The Message of The Quran',
        });
      },
    );
  });
}
