import 'package:the_message_of_the_quran/core/models/tajweed_word_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class TajweedDbHelper {
  TajweedDbHelper._();

  /// Returns all words for a given verse-range ordered by ayah and position.
  static Future<List<TajweedWordModel>> getWordsForBlock({
    required int surahNo,
    required int verseFrom,
    required int verseTo,
  }) async {
    final rows = await MoqApiClient.instance.getList(
      '/tajweed/words',
      query: {'surah': surahNo, 'verseFrom': verseFrom, 'verseTo': verseTo},
    );
    return rows.map(TajweedWordModel.fromJson).toList();
  }

  /// Returns every image URL stored in the table (for pre-downloading).
  static Future<List<String>> getAllImageUrls() async {
    return MoqApiClient.instance.getStringList('/tajweed/image-urls');
  }
}
