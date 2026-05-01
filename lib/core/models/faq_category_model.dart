import 'package:the_message_of_the_quran/core/models/help_model.dart';

class FaqCategory {
  final String categoryName;
  final List<HelpModel> items;

  FaqCategory({
    required this.categoryName,
    required this.items,
  });
}
