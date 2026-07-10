import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String english = 'en';
  static const String malayalam = 'ml';

  String _currentLanguage = english;
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
    _currentLanguage = _prefs?.getString(_languageKey) ?? english;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLanguage(String language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    await _prefs?.setString(_languageKey, language);
    notifyListeners();
  }
}
