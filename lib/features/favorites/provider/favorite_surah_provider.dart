import 'package:flutter/foundation.dart';
import 'package:the_message_of_the_quran/core/services/database/favorite_surah_db_helper.dart';

/// Tracks which surahs the reader has marked as a favourite. Backed by the
/// local user database, same as bookmarks — favourites are per-device.
class FavoriteSurahProvider extends ChangeNotifier {
  final Set<int> _favoriteSurahNumbers = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Ordered most-recently-favourited first.
  List<int> get favoriteSurahNumbers => _favoriteSurahNumbers.toList();

  bool isFavorite(int surahNumber) =>
      _favoriteSurahNumbers.contains(surahNumber);

  Future<void> load() async {
    final rows = await FavoriteSurahDbHelper.getAll();
    _favoriteSurahNumbers
      ..clear()
      ..addAll(rows.map((r) => r.surahNumber));
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggle(int surahNumber) async {
    if (_favoriteSurahNumbers.contains(surahNumber)) {
      _favoriteSurahNumbers.remove(surahNumber);
      notifyListeners();
      await FavoriteSurahDbHelper.remove(surahNumber);
    } else {
      _favoriteSurahNumbers.add(surahNumber);
      notifyListeners();
      await FavoriteSurahDbHelper.add(surahNumber);
    }
  }
}
