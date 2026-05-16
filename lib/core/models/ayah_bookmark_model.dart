import 'package:the_message_of_the_quran/core/constants/db_constants.dart';

class BookmarkNavigationTarget {
  static const String surah = 'surah';
  static const String mushaf = 'mushaf';

  static bool isValid(String? value) {
    return value == surah || value == mushaf;
  }

  static String normalize(String? value) {
    return value == mushaf ? mushaf : surah;
  }
}

class AyahBookmarkModel {
  final int surahNumber;
  final int ayahId;
  final String? surahName;
  final String? ayaText;
  final String? surahArabicName;
  final String? surahArabicNumber;
  final String? label;
  final String navigationTarget;

  AyahBookmarkModel({
    required this.surahNumber,
    required this.ayahId,
    this.surahName,
    this.ayaText,
    this.surahArabicName,
    this.surahArabicNumber,
    this.label,
    String? navigationTarget,
  }) : navigationTarget = BookmarkNavigationTarget.normalize(navigationTarget);

  Map<String, dynamic> toMap() {
    return {
      DbConstants.bookmarkSurahNumber: surahNumber,
      DbConstants.bookmarkAyahId: ayahId,
      DbConstants.bookmarkSurahName: surahName,
      DbConstants.bookmarkAyaText: ayaText,
      DbConstants.bookmarkSurahArabicName: surahArabicName,
      DbConstants.bookmarkSurahArabicNumber: surahArabicNumber,
      DbConstants.bookmarkLabel: label,
      DbConstants.bookmarkNavigationTarget: navigationTarget,
    };
  }

  factory AyahBookmarkModel.fromMap(Map<String, dynamic> map) {
    return AyahBookmarkModel(
      surahNumber: map[DbConstants.bookmarkSurahNumber] as int? ?? 0,
      ayahId: map[DbConstants.bookmarkAyahId] as int? ?? 0,
      surahName: map[DbConstants.bookmarkSurahName] as String?,
      ayaText: map[DbConstants.bookmarkAyaText] as String?,
      surahArabicName: map[DbConstants.bookmarkSurahArabicName] as String?,
      surahArabicNumber: map[DbConstants.bookmarkSurahArabicNumber] as String?,
      label: map[DbConstants.bookmarkLabel] as String?,
      navigationTarget: map[DbConstants.bookmarkNavigationTarget] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AyahBookmarkModel &&
          runtimeType == other.runtimeType &&
          surahNumber == other.surahNumber &&
          ayahId == other.ayahId &&
          navigationTarget == other.navigationTarget;

  @override
  int get hashCode => Object.hash(surahNumber, ayahId, navigationTarget);
}
