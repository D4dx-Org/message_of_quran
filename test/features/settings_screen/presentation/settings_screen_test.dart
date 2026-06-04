import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/settings_screen.dart';

void main() {
  test('General section visibility is disabled on web only', () {
    expect(SettingsScreen.shouldShowGeneralSection(isWeb: true), isFalse);
    expect(SettingsScreen.shouldShowGeneralSection(isWeb: false), isTrue);
  });
}