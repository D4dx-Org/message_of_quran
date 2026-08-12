import 'package:the_message_of_the_quran/core/models/appendix_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class AppendixDbHelper {
  static Future<List<AppendixModel>> getAppendices({
    bool malayalam = false,
  }) async {
    final rows = await MoqApiClient.instance.getList(
      '/appendices',
      query: {'malayalam': malayalam},
    );
    return rows.map((map) => AppendixModel.fromJson(map)).toList();
  }

  static Future<AppendixModel?> getAppendixByNumber(
    int number, {
    bool malayalam = false,
  }) async {
    final row = await MoqApiClient.instance.getObject(
      '/appendices/$number',
      query: {'malayalam': malayalam},
    );
    if (row == null) return null;
    return AppendixModel.fromJson(row);
  }
}
