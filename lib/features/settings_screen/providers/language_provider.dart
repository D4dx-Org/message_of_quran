import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String english = 'en';
  static const String malayalam = 'ml';

  /// Language read from disk during bootstrap, before any widget builds.
  ///
  /// The constructor used to start an async read and default to English until
  /// it landed, so the first frame — and anything that captured the language
  /// once, such as a bookmark list fetching its translations — used English
  /// even when Malayalam was saved, and only corrected itself on a later run.
  static String? _seededLanguage;

  static Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _seededLanguage = prefs.getString(_languageKey) ?? english;
  }

  String _currentLanguage = _seededLanguage ?? english;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  String get currentLanguage => _currentLanguage;
  bool get isMalayalam => _currentLanguage == malayalam;

  LanguageProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
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
