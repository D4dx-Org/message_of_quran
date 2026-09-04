import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/widgets/interpretation_note_marker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<int> pumpMarker(
    WidgetTester tester, {
    int? contentFontSize,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (contentFontSize != null) 'content_font_size': contentFontSize,
    });
    var taps = 0;

    await tester.pumpWidget(
      ChangeNotifierProvider(
        // A fresh key per pump, so a second call in the same test builds a
        // new provider instead of reusing the first one's font size.
        key: ValueKey(contentFontSize),
        create: (_) => FontSizeChangerProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Alif. Lam. Mim.'),
                    buildInterpretationNoteMarkerSpan(
                      number: 1,
                      onTap: () => taps++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    return taps;
  }

  Finder markerTarget() => find.byType(SizedBox).last;

  testWidgets('the footnote badge carries a large touch target', (
    tester,
  ) async {
    await pumpMarker(tester);

    final size = tester.getSize(markerTarget());
    // The old badge was 18x18 — far under anything an older reader can hit.
    expect(size.height, greaterThanOrEqualTo(34));
    expect(size.width, greaterThanOrEqualTo(44));
  });

  testWidgets('a tap at the edge of the target still opens the note', (
    tester,
  ) async {
    var taps = 0;
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => FontSizeChangerProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: 'Alif. Lam. Mim.'),
                    buildInterpretationNoteMarkerSpan(
                      number: 1,
                      onTap: () => taps++,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Well clear of the drawn circle, in the padding that used to be dead.
    final rect = tester.getRect(markerTarget());
    await tester.tapAt(Offset(rect.right - 2, rect.bottom - 2));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('the target grows with the reader\'s font size', (tester) async {
    await pumpMarker(tester, contentFontSize: 12);
    final small = tester.getSize(markerTarget());

    await pumpMarker(tester, contentFontSize: 26);
    final large = tester.getSize(markerTarget());

    expect(large.width, greaterThan(small.width));
    expect(large.height, greaterThan(small.height));
  });
}
