import 'package:the_message_of_the_quran/core/models/foreword_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class ForewordDbHelper {
  static Future<ForewordModel?> getForeword() async {
    final row = await MoqApiClient.instance.getObject('/foreword');
    if (row == null) return null;
    return ForewordModel.fromJson(row);
  }
}
