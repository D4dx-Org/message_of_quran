import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/services/api/common_email_api.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/features/common_email/models/common_email_requests.dart';
import 'package:the_message_of_the_quran/features/common_email/presentation/feature_request_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';

void main() {
  Future<void> pumpFeatureRequestScreen(
    WidgetTester tester,
    _RecordingCommonEmailApi api,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final themeProvider = ThemeProvider();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<LanguageProvider>(
            create: (_) => LanguageProvider(),
          ),
        ],
        child: MaterialApp(
          theme: themeProvider.lightTheme,
          home: FeatureRequestScreen(api: api),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('feature request screen requires all fields', (tester) async {
    final api = _RecordingCommonEmailApi();
    await pumpFeatureRequestScreen(tester, api);

    await tester.ensureVisible(
      find.byKey(const ValueKey('feature-request-submit-button')),
    );
    await tester.tap(
      find.byKey(const ValueKey('feature-request-submit-button')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Enter your name.'), findsOneWidget);
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your phone number.'), findsOneWidget);
    expect(
      find.text('Please choose where this feature should be added.'),
      findsOneWidget,
    );
    expect(find.text('Please choose a feature category.'), findsOneWidget);
    expect(find.text('Enter a feature title.'), findsOneWidget);
    expect(find.text('Enter a description.'), findsOneWidget);
    expect(api.featureRequestSubmission, isNull);
  });

  testWidgets('feature request screen submits the required payload', (
    tester,
  ) async {
    final api = _RecordingCommonEmailApi();
    await pumpFeatureRequestScreen(tester, api);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Fathima Zahra');
    await tester.enterText(fields.at(1), 'fathima@example.com');
    await tester.enterText(fields.at(2), '+919876543210');
    await tester.ensureVisible(find.text('Mobile App'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Mobile App'));
    await tester.ensureVisible(find.text('Content Feature'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Content Feature'));
    await tester.ensureVisible(find.text('Feature Title'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(fields.at(3), 'Add bookmarking');
    await tester.ensureVisible(find.text('Description'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(fields.at(4), 'Please add bookmarking for ayahs.');

    await tester.ensureVisible(
      find.byKey(const ValueKey('feature-request-submit-button')),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(
      find.byKey(const ValueKey('feature-request-submit-button')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(api.featureRequestSubmission, isNotNull);
    expect(api.featureRequestSubmission!.name, 'Fathima Zahra');
    expect(api.featureRequestSubmission!.email, 'fathima@example.com');
    expect(api.featureRequestSubmission!.phone, '+919876543210');
    expect(api.featureRequestSubmission!.title, 'Add bookmarking');
    expect(
      api.featureRequestSubmission!.description,
      'Please add bookmarking for ayahs.',
    );
    expect(
      api.featureRequestSubmission!.targetPlatform,
      FeatureRequestTargetPlatform.mobile,
    );
    expect(
      api.featureRequestSubmission!.category,
      FeatureRequestCategory.content,
    );
    expect(find.text('Feature request sent successfully.'), findsOneWidget);
  });
}

class _RecordingCommonEmailApi extends CommonEmailApi {
  FeatureRequestSubmission? featureRequestSubmission;

  @override
  Future<void> sendFeatureRequest(FeatureRequestSubmission request) async {
    featureRequestSubmission = request;
  }
}
