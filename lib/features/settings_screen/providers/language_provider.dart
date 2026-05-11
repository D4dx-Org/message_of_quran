import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String english = 'en';
  static const String malayalam = 'ml';

  String _currentLanguage = english;
  SharedPreferences? _prefs;
  bool _isInitialized = false;

  String get currentLanguage => _currentLanguage;
  // TODO: Re-enable when Malayalam DB is ready
  // bool get isMalayalam => _currentLanguage == malayalam;
  bool get isMalayalam => false;

  LanguageProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;
    _prefs = await SharedPreferences.getInstance();
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
