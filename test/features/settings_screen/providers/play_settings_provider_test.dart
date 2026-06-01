import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/play_settings_provider.dart';

void main() {
	test('reciter list excludes Abdulrahman Al-Ossi', () {
		final reciterNames = PlaySettingsProvider.reciters
				.map((reciter) => reciter.name)
				.toList();

		expect(reciterNames, isNot(contains('Abdulrahman Al-Ossi')));
	});
}
