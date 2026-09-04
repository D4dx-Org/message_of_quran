import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSizeChangerProvider extends ChangeNotifier {
  static const _fontTypeKey = 'quran_font_type';
  static const _quranFontSizeKey = 'quran_font_size';
  static const _contentFontSizeKey = 'content_font_size';
  static const _translationJustifyKey = 'translation_justify';
  static const _interpretationJustifyKey = 'interpretation_justify';
  static const _quranJustifyKey = 'quran_justify';
  static const String defaultFont = 'Amiri';
  static const String removedFont = 'Uthmani';

  static const List<String> availableFonts = [
    'Amiri',
    'Scheherazade',
    'Lateef',
    'AmiriQuran',
    'QuranTaha',
  ];

  static const Map<String, String> fontDisplayNames = {
    'Amiri': 'Amiri',
    'Scheherazade': 'Scheherazade',
    'Lateef': 'Lateef',
    'AmiriQuran': 'Amiri Quran',
    'QuranTaha': 'QuranTaha',
  };

  static const int minFontSize = 10;
  static const int maxFontSize = 30;

  int quranFontSize = 22;

  /// One size for every piece of readable content: the verse translations, the
  /// footnotes, and the prose on the Translator, Foreword, Appendix and Works
  /// of Reference pages. Titles, headers and list rows are not affected.
  int contentFontSize = 18;
  bool translationJustify = true;
  bool interpretationJustify = true;
  bool quranJustify = true;
  // Default font for the Qur'an text (used when SharedPreferences has no value yet).
  String fontType = defaultFont;

  FontSizeChangerProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedFont = prefs.getString(_fontTypeKey);
    fontType = normalizeFont(savedFont);
    if (savedFont != fontType) {
      await prefs.setString(_fontTypeKey, fontType);
    }
    quranFontSize = _clamp(prefs.getInt(_quranFontSizeKey) ?? quranFontSize);
    contentFontSize = _clamp(
      prefs.getInt(_contentFontSizeKey) ?? contentFontSize,
    );
    translationJustify = prefs.getBool(_translationJustifyKey) ?? true;
    interpretationJustify = prefs.getBool(_interpretationJustifyKey) ?? true;
    quranJustify = prefs.getBool(_quranJustifyKey) ?? true;
    notifyListeners();
  }

  static String normalizeFont(String? savedFont) {
    if (savedFont == null || savedFont == removedFont) {
      return defaultFont;
    }

    return availableFonts.contains(savedFont) ? savedFont : defaultFont;
  }

  int _clamp(int size) => size.clamp(minFontSize, maxFontSize);

  Future<void> _save(String key, int size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, size);
  }

  void increment(bool isQuran) {
    if (isQuran) {
      if (quranFontSize >= maxFontSize) return;
      quranFontSize++;
      _save(_quranFontSizeKey, quranFontSize);
    } else {
      if (contentFontSize >= maxFontSize) return;
      contentFontSize++;
      _save(_contentFontSizeKey, contentFontSize);
    }
    notifyListeners();
  }

  void decrement(bool isQuran) {
    if (isQuran) {
      if (quranFontSize <= minFontSize) return;
      quranFontSize--;
      _save(_quranFontSizeKey, quranFontSize);
    } else {
      if (contentFontSize <= minFontSize) return;
      contentFontSize--;
      _save(_contentFontSizeKey, contentFontSize);
    }
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
