import 'package:the_message_of_the_quran/core/models/contact_content_model.dart';
import 'package:the_message_of_the_quran/core/models/contact_model.dart';
import 'package:the_message_of_the_quran/core/services/api/moq_api_client.dart';

class ContactDbHelper {
  /// The source table is absent from the shipped db; backend returns an empty list.
  static Future<List<ContactModel>> getContactInfo() async {
    return [];
  }

  static Future<ContactContentModel?> getContactContent() async {
    final row = await MoqApiClient.instance.getObject(
      '/contact',
      query: {'malayalam': true},
    );
    if (row == null) return null;
    return ContactContentModel.fromJson(row);
  }

  static Future<ContactContentModel?> getEnglishContactContent() async {
    final row = await MoqApiClient.instance.getObject('/contact/english');
    if (row == null) return null;
    return ContactContentModel.fromEnglishJson(row);
  }
}
