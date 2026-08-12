import 'package:the_message_of_the_quran/core/models/juz_hizb_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class JuzHizbDbHelper {
  /// Returns the 30 Juz entries with their starting surah and ayah.
  static Future<List<JuzHizbModel>> getAllJuz() => _fetch('/juzs');

  /// Returns the 60 Hizb entries with their starting surah and ayah.
  static Future<List<JuzHizbModel>> getAllHizb() => _fetch('/hizbs');

  static Future<List<JuzHizbModel>> _fetch(String path) async {
    final rows = await MoqApiClient.instance.getList(path);
    return List.generate(
      rows.length,
      (i) => JuzHizbModel.fromMap(rows[i], i + 1),
    );
  }
}
