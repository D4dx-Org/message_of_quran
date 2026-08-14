import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class FavoriteSurahModel {
  const FavoriteSurahModel({required this.surahNumber, required this.createdAt});

  final int surahNumber;
  final int createdAt;

  factory FavoriteSurahModel.fromMap(Map<String, dynamic> map) {
    return FavoriteSurahModel(
      surahNumber: map[DbConstants.favoriteSurahNumber] as int,
      createdAt: map[DbConstants.favoriteCreatedAt] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.favoriteSurahNumber: surahNumber,
      DbConstants.favoriteCreatedAt: createdAt,
    };
  }
}
