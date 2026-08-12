import 'package:the_message_of_the_quran/core/models/ml_preface_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class MlPrefaceDbHelper {
  static Future<MlPrefaceModel?> getPreface() async {
    final row = await MoqApiClient.instance.getObject('/ml-preface');
    if (row == null) return null;
    return MlPrefaceModel.fromJson(row);
  }
}
