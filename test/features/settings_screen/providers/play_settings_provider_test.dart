import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/play_settings_provider.dart';

void main() {
  group('ReciterAudioSource', () {
    test('builds EveryAyah URLs for supported reciters', () {
      final reciter = PlaySettingsProvider.reciters.firstWhere(
        (item) => item.name == 'Abdul Basit Abdul Samad (Mujawwad)',
      );

      expect(
        reciter.audioSource.buildAyahUrl(1, 1),
        'https://everyayah.com/data/Abdul_Basit_Mujawwad_128kbps/001001.mp3',
      );
      expect(reciter.audioSource.isConfigured, isTrue);
    });

    test('keeps Al-Ossi on a configurable custom per-ayah source', () {
      final reciter = PlaySettingsProvider.reciters.firstWhere(
        (item) => item.name == 'Abdulrahman Al-Ossi',
      );

      expect(reciter.audioSource.kind, ReciterAudioSourceKind.customPerAyah);
      expect(reciter.audioSource.isConfigured, isFalse);
      expect(reciter.audioSource.buildAyahUrl(1, 1), isNull);
    });
  });
}