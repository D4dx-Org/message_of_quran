import 'package:the_message_of_the_quran/core/models/preface_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class PrefaceDbHelper {
  /// Returns the introduction/preface text for the given surah.
  static Future<List<PrefaceModel>> getPrefaceBySurahId(int surahId,
      {bool malayalam = false}) async {
    final rows = await MoqApiClient.instance.getList(
      '/prefaces/$surahId',
      query: {'malayalam': malayalam},
    );
    return rows.map(PrefaceModel.fromJson).toList();
  }

  static Future<PrefaceModel?> getGeneralPreface() async {
    return null;
  }
}
