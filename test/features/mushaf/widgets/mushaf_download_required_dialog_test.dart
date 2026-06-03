import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/features/mushaf/widgets/mushaf_download_required_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    required ThemeMode themeMode,
  }) async {
    final provider = ThemeProvider();

    await tester.pumpWidget(
      MaterialApp(
        theme: provider.lightTheme,
        darkTheme: provider.darkTheme,
        themeMode: themeMode,
        home: Scaffold(
          body: Center(
            child: MushafDownloadRequiredDialog(
              onCancel: () {},
              onDownload: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('download dialog uses higher contrast secondary styling in dark mode', (
    tester,
  ) async {
    await pumpDialog(tester, themeMode: ThemeMode.dark);

    final dialogContext = tester.element(
      find.byType(MushafDownloadRequiredDialog),
    );
    final theme = Theme.of(dialogContext);
    final titleRowFinder = find.ancestor(
      of: find.text('Download Required'),
      matching: find.byType(Row),
    );
    final titleIcon = tester.widget<Icon>(
      find.descendant(
        of: titleRowFinder.first,
        matching: find.byWidgetPredicate(
          (widget) => widget is Icon && widget.icon == Icons.download_rounded,
        ),
      ).first,
    );
    final cancelText = tester.widget<Text>(find.text('Cancel'));

    expect(titleIcon.color, theme.colorScheme.onSurface);
    expect(titleIcon.color, isNot(AppTheme.appIconTheme));
    expect(
      cancelText.style?.color,
      theme.colorScheme.onSurface.withValues(alpha: 0.78),
    );
    expect(cancelText.style?.color, isNot(const Color(0xFF525866)));
  });
}