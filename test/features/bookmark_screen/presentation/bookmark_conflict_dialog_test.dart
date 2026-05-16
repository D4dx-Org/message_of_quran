import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_message_of_the_quran/core/models/ayah_bookmark_model.dart';
import 'package:the_message_of_the_quran/features/bookmark_screen/presentation/bookmark_conflict_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('shows the conflict dialog with one-row actions', (
    WidgetTester tester,
  ) async {
    await _pumpConflictDialogHost(tester, onResult: (_) {});

    expect(find.text('Bookmark already exists'), findsOneWidget);
    expect(
      find.textContaining(
        'You already saved a Quran Block bookmark in Al-Fatihah.',
      ),
      findsOneWidget,
    );

    final cancelButton = find.widgetWithText(OutlinedButton, 'Cancel');
    final keepBothButton = find.widgetWithText(FilledButton, 'Keep both');
    final replaceButton = find.widgetWithText(FilledButton, 'Replace');

    expect(cancelButton, findsOneWidget);
    expect(keepBothButton, findsOneWidget);
    expect(replaceButton, findsOneWidget);

    final cancelTop = tester.getTopLeft(cancelButton).dy;
    final keepBothTop = tester.getTopLeft(keepBothButton).dy;
    final replaceTop = tester.getTopLeft(replaceButton).dy;

    expect(cancelTop, closeTo(keepBothTop, 0.1));
    expect(cancelTop, closeTo(replaceTop, 0.1));
  });

  testWidgets('returns null when cancel is tapped', (
    WidgetTester tester,
  ) async {
    var didClose = false;
    BookmarkConflictResolution? result = BookmarkConflictResolution.replace;

    await _pumpConflictDialogHost(
      tester,
      onResult: (value) {
        didClose = true;
        result = value;
      },
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(didClose, isTrue);
    expect(result, isNull);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('returns keepBoth when keep both is tapped', (
    WidgetTester tester,
  ) async {
    BookmarkConflictResolution? result;

    await _pumpConflictDialogHost(
      tester,
      onResult: (value) => result = value,
      navigationTarget: BookmarkNavigationTarget.mushaf,
      surahName: 'Al-Baqarah',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Keep both'));
    await tester.pumpAndSettle();

    expect(result, BookmarkConflictResolution.keepBoth);
  });

  testWidgets('returns replace when replace is tapped', (
    WidgetTester tester,
  ) async {
    BookmarkConflictResolution? result;

    await _pumpConflictDialogHost(tester, onResult: (value) => result = value);

    await tester.tap(find.widgetWithText(FilledButton, 'Replace'));
    await tester.pumpAndSettle();

    expect(result, BookmarkConflictResolution.replace);
  });
}

Future<void> _pumpConflictDialogHost(
  WidgetTester tester, {
  required void Function(BookmarkConflictResolution? result) onResult,
  String navigationTarget = BookmarkNavigationTarget.surah,
  String? surahName = 'Al-Fatihah',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () async {
                  final result = await showBookmarkConflictDialog(
                    context,
                    navigationTarget: navigationTarget,
                    surahName: surahName,
                  );
                  onResult(result);
                },
                child: const Text('Open dialog'),
              ),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.widgetWithText(FilledButton, 'Open dialog'));
  await tester.pumpAndSettle();
}
