import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/juz_hizb_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JuzHizbProvider selected Juz persistence', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('restores the persisted selected Juz number', () async {
      SharedPreferences.setMockInitialValues({'selected_juz_number': 2});
      final provider = JuzHizbProvider();

      await provider.restoreSelectedJuz();

      expect(provider.selectedJuzNumber, 2);
    });

    test('selectJuz updates state and persists the chosen Juz', () async {
      final provider = JuzHizbProvider();

      await provider.selectJuz(2);

      final prefs = await SharedPreferences.getInstance();

      expect(provider.selectedJuzNumber, 2);
      expect(prefs.getInt('selected_juz_number'), 2);
    });
  });
}
