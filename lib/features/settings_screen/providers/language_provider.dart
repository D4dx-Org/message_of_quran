import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String english = 'en';
  static const String malayalam = 'ml';

  /// Language read from disk before any widget builds. preload() only starts
  /// the read, so without this the first frame still reported English and
  /// anything that captured the language once — a bookmark list fetching its
  /// translations, say — used English even with Malayalam saved.
  static String? _seededLanguage;

  static Future<void> loadSaved() async {
    final prefs = await (_preloadedPrefs ??= SharedPreferences.getInstance());
    _seededLanguage = prefs.getString(_languageKey) ?? english;
  }

  String _currentLanguage = _seededLanguage ?? english;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  // Kicked off as early as possible (before runApp) so the read is already
  // in flight/resolved by the time this provider is constructed, avoiding a
  // visible flash back to English on the first frame after a web refresh.
  static Future<SharedPreferences>? _preloadedPrefs;

  static void preload() {
    _preloadedPrefs ??= SharedPreferences.getInstance();
  }

  String get currentLanguage => _currentLanguage;
  bool get isMalayalam => _currentLanguage == malayalam;

  LanguageProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _prefs = await (_preloadedPrefs ??= SharedPreferences.getInstance());
    final saved = _prefs?.getString(_languageKey) ?? english;
    _isInitialized = true;
    if (saved == _currentLanguage) return;
    _currentLanguage = saved;
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    await _prefs?.setString(_languageKey, language);
    notifyListeners();
  }
}
