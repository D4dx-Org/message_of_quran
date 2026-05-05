import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeChangerProvider extends ChangeNotifier {
  static const _fontTypeKey = 'quran_font_type';
  static const _translationJustifyKey = 'translation_justify';
  static const _interpretationJustifyKey = 'interpretation_justify';
  static const _quranJustifyKey = 'quran_justify';

  static const List<String> availableFonts = [
    'Amiri',
    'Uthmani',
    'Scheherazade',
    'Lateef',
    'AmiriQuran',
    'QuranTaha',
  ];

  static const Map<String, String> fontDisplayNames = {
    'Amiri': 'Amiri',
    'Uthmani': 'Uthmani',
    'Scheherazade': 'Scheherazade',
    'Lateef': 'Lateef',
    'AmiriQuran': 'Amiri Quran',
    'QuranTaha': 'QuranTaha',
  };

  int quranFontSize = 19;
  int quranTransaltionFontSize = 15;
  int interpretationFontSize = 14;
  bool translationJustify = true;
  bool interpretationJustify = true;
  bool quranJustify = true;
  // Default font for the Qur'an text (used when SharedPreferences has no value yet).
  String fontType = "Uthmani";

  FontSizeChangerProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    String defaultFont = 'Uthmani';
    final savedFont = prefs.getString(_fontTypeKey) ?? defaultFont;
    fontType = availableFonts.contains(savedFont) ? savedFont : defaultFont;
    translationJustify = prefs.getBool(_translationJustifyKey) ?? true;
    interpretationJustify = prefs.getBool(_interpretationJustifyKey) ?? true;
    quranJustify = prefs.getBool(_quranJustifyKey) ?? true;
    notifyListeners();
  }

  void increment(bool isQuran) {
    if (isQuran) {
      if (quranFontSize > 29) return;
      quranFontSize++;
    } else {
      if (quranTransaltionFontSize > 29) return;
      quranTransaltionFontSize++;
    }
    notifyListeners();
  }

  void decrement(bool isQuran) {
    if (isQuran) {
      if (quranFontSize < 11) return;
      quranFontSize--;
    } else {
      if (quranTransaltionFontSize < 11) return;
      quranTransaltionFontSize--;
    }
    notifyListeners();
  }

  void incrementInterpretation() {
    if (interpretationFontSize > 29) return;
    interpretationFontSize++;
    notifyListeners();
  }

  void decrementInterpretation() {
    if (interpretationFontSize < 11) return;
    interpretationFontSize--;
    notifyListeners();
  }

  Future<void> setFont(String font) async {
    if (!availableFonts.contains(font) || fontType == font) return;
    fontType = font;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontTypeKey, font);
    notifyListeners();
  }

  Future<void> setTranslationJustify(bool value) async {
    if (translationJustify == value) return;
    translationJustify = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_translationJustifyKey, value);
    notifyListeners();
  }

  Future<void> setInterpretationJustify(bool value) async {
    if (interpretationJustify == value) return;
    interpretationJustify = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_interpretationJustifyKey, value);
    notifyListeners();
  }

  Future<void> setQuranJustify(bool value) async {
    if (quranJustify == value) return;
    quranJustify = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_quranJustifyKey, value);
    notifyListeners();
  }
}
