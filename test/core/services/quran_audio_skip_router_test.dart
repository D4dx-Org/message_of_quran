import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/core/services/quran_audio_skip_router.dart';

void main() {
  group('QuranAudioSkipRouter', () {
    test('routes skip actions to the active delegate', () async {
      final router = QuranAudioSkipRouter();
      final events = <String>[];
      final owner = Object();

      router.setDelegate(
        owner: owner,
        onNext: () async => events.add('next'),
        onPrevious: () async => events.add('previous'),
      );

      expect(await router.skipToNext(), isTrue);
      expect(await router.skipToPrevious(), isTrue);
      expect(events, ['next', 'previous']);
    });

    test('ignores clear requests from a different owner', () async {
      final router = QuranAudioSkipRouter();
      var invoked = false;
      final owner = Object();

      router.setDelegate(
        owner: owner,
        onNext: () async {
          invoked = true;
        },
      );

      router.clearDelegate(owner: Object());
      expect(await router.skipToNext(), isTrue);
      expect(invoked, isTrue);
    });

    test('falls back when no delegate is registered', () async {
      final router = QuranAudioSkipRouter();

      expect(await router.skipToNext(), isFalse);
      expect(await router.skipToPrevious(), isFalse);
    });
  });
}