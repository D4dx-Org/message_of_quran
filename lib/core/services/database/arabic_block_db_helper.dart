import 'package:the_message_of_the_quran/core/models/arabic_block_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class ArabicBlockDbHelper {
  static Future<List<ArabicBlockModel>> getArabicBlocksBySurah(
    int surahNumber,
  ) async {
    final rows = await MoqApiClient.instance.getList(
      '/surahs/$surahNumber/arabic',
    );
    return rows.map(ArabicBlockModel.fromQuranAyasJson).toList();
  }

  /// Returns a single [ArabicBlockModel] for [surahNumber]:[ayahNumber].
  static Future<ArabicBlockModel?> getArabicBlockByVerse(
    int surahNumber,
    int ayahNumber,
  ) async {
    final row = await MoqApiClient.instance.getObject(
      '/surahs/$surahNumber/arabic/$ayahNumber',
    );
    if (row == null) return null;
    return ArabicBlockModel.fromQuranAyasJson(row);
  }
}
