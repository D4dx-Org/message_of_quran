import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/core/services/api/common_email_api.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/features/common_email/models/common_email_requests.dart';
import 'package:the_message_of_the_quran/features/common_email/presentation/feedback_screen.dart';

void main() {
  Future<void> pumpFeedbackScreen(
    WidgetTester tester,
    _RecordingCommonEmailApi api,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      MaterialApp(
        theme: themeProvider.lightTheme,
        home: FeedbackScreen(api: api),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('feedback screen requires all fields', (tester) async {
    final api = _RecordingCommonEmailApi();
    await pumpFeedbackScreen(tester, api);

    await tester.ensureVisible(
      find.byKey(const ValueKey('feedback-submit-button')),
    );
    await tester.tap(find.byKey(const ValueKey('feedback-submit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Enter your name.'), findsOneWidget);
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your phone number.'), findsOneWidget);
    expect(find.text('Please choose a rating.'), findsOneWidget);
    expect(find.text('Enter your feedback message.'), findsOneWidget);
    expect(api.feedbackRequest, isNull);
  });

  testWidgets('feedback screen submits the required payload', (tester) async {
    final api = _RecordingCommonEmailApi();
    await pumpFeedbackScreen(tester, api);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Ali Rahman');
    await tester.enterText(fields.at(1), 'ali@example.com');
    await tester.enterText(fields.at(2), '+919876543210');
    await tester.ensureVisible(find.text('Good'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Good'));
    await tester.enterText(fields.at(3), 'Great app experience.');

    await tester.ensureVisible(
      find.byKey(const ValueKey('feedback-submit-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('feedback-submit-button')));
    await tester.pumpAndSettle();

    expect(api.feedbackRequest, isNotNull);
    expect(api.feedbackRequest!.name, 'Ali Rahman');
    expect(api.feedbackRequest!.email, 'ali@example.com');
    expect(api.feedbackRequest!.phone, '+919876543210');
    expect(api.feedbackRequest!.rating, FeedbackRating.good);
    expect(api.feedbackRequest!.message, 'Great app experience.');
    expect(find.text('Feedback sent successfully.'), findsOneWidget);
  });
}

class _RecordingCommonEmailApi extends CommonEmailApi {
  FeedbackRequest? feedbackRequest;

  @override
  Future<void> sendFeedback(FeedbackRequest request) async {
    feedbackRequest = request;
  }
}
