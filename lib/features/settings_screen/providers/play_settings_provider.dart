import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';

enum PlayMode { singleBlock, continuous }

class ReciterInfo {
  final String name;
  final String folderName;
  /// Overrides the default everyayah.com URL pattern when a reciter's
  /// audio is hosted elsewhere with a different naming scheme.
  final String Function(int surahNumber, int ayahId)? urlBuilder;
  const ReciterInfo({
    required this.name,
    required this.folderName,
    this.urlBuilder,
  });
}

String _thafheemAudioUrl(int surahNumber, int ayahId) {
  final surah = surahNumber.toString().padLeft(3, '0');
  final ayah = ayahId.toString().padLeft(3, '0');
  return '${ApiConstants.thafheemAudioBaseUrl}/al-afasy/QA${surah}_$ayah.ogg';
}

class PlaySettingsProvider extends ChangeNotifier {
  // v2 key — old 'play_mode' stored singleBlock(0) as default, so a fresh
  // key ensures all users start with continuous until they explicitly change it.
  static const _playModeKey = 'play_mode_v2';
  static const _reciterKey = 'reciter_index_v2';
  static const _legacyReciterKey = 'reciter_index';
  static const _removedReciterLegacyIndex = 3;
  static const _showTranslationKey = 'show_translation';
  static const _speedKey = 'playback_speed';

  static const List<double> speedPresets = [0.5, 1.0, 1.5, 2.0];

  static const List<ReciterInfo> reciters = [
    ReciterInfo(
        name: 'Abdul Basit Abdul Samad (Mujawwad)',
        folderName: 'Abdul_Basit_Mujawwad_128kbps'),
    ReciterInfo(
        name: 'Abdurrahmaan As-Sudais',
        folderName: 'Abdurrahmaan_As-Sudais_192kbps'),
    ReciterInfo(
        name: "Sa'ud Ash-Shuraym",
        folderName: 'Saood_ash-Shuraym_128kbps'),
    ReciterInfo(
        name: 'Abdullah Basfar', folderName: 'Abdullah_Basfar_192kbps'),
    ReciterInfo(
        name: 'Ahmed ibn Ali Al-Ajamy',
        folderName: 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net'),
    ReciterInfo(name: 'Ali Jaber', folderName: 'Ali_Jaber_64kbps'),
    ReciterInfo(name: 'Fares Abbad', folderName: 'Fares_Abbad_64kbps'),
    ReciterInfo(
        name: 'Muhsin Al Qasim', folderName: 'Muhsin_Al_Qasim_192kbps'),
    ReciterInfo(
        name: 'Nasser Alqatami', folderName: 'Nasser_Alqatami_128kbps'),
    ReciterInfo(
        name: 'Abdullah Awwaad Al-Juhayni',
        folderName: 'Abdullaah_3awwaad_Al-Juhaynee_128kbps'),
    ReciterInfo(
        name: 'Mahmoud Khalil Al-Husary', folderName: 'Husary_128kbps'),
    ReciterInfo(
        name: 'Muhammad Siddiq Al-Minshawi (Mujawwad)',
        folderName: 'Minshawy_Mujawwad_192kbps'),
    ReciterInfo(name: 'Saad Al-Ghamdi', folderName: 'Ghamadi_40kbps'),
    ReciterInfo(
        name: 'Mishary Rashid Al-Afasy',
        folderName: 'al-afasy',
        urlBuilder: _thafheemAudioUrl),
  ];

  PlayMode _playMode = PlayMode.continuous;
  int _selectedReciterIndex = 0;
  bool _showTranslation = true;
  double _playbackSpeed = 1.0;

  PlayMode get playMode => _playMode;
  int get selectedReciterIndex => _selectedReciterIndex;
  ReciterInfo get selectedReciter => reciters[_selectedReciterIndex];
  bool get showTranslation => _showTranslation;
  double get playbackSpeed => _playbackSpeed;

  PlaySettingsProvider() {
    // Defer until after the first frame so notifyListeners() is never called
    // while the widget tree is locked (during the initial build), which would
    // throw: "setState() or markNeedsBuild() called when widget tree was locked."
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  static int _migrateLegacyReciterIndex(int index) {
    if (index < 0) {
      return 0;
    }
    if (index == _removedReciterLegacyIndex) {
      return 0;
    }
    if (index > _removedReciterLegacyIndex) {
      return index - 1;
    }
    return index;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_playModeKey) ?? PlayMode.continuous.index;
      _playMode =
          PlayMode.values[modeIndex.clamp(0, PlayMode.values.length - 1)];
      final savedReciterIndex = prefs.containsKey(_reciterKey)
          ? prefs.getInt(_reciterKey) ?? 0
          : _migrateLegacyReciterIndex(prefs.getInt(_legacyReciterKey) ?? 0);
      _selectedReciterIndex = savedReciterIndex.clamp(0, reciters.length - 1);
      if (!prefs.containsKey(_reciterKey)) {
        await prefs.setInt(_reciterKey, _selectedReciterIndex);
      }
      _showTranslation = prefs.getBool(_showTranslationKey) ?? true;
      final savedSpeed = prefs.getDouble(_speedKey) ?? 1.0;
      _playbackSpeed = speedPresets.contains(savedSpeed) ? savedSpeed : 1.0;
    } catch (e) {
      debugPrint('PlaySettingsProvider: load failed — $e');
    }
    notifyListeners();
  }

  Future<void> setPlayMode(PlayMode mode) async {
    if (_playMode == mode) return;
    _playMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_playModeKey, mode.index);
    } catch (e) {
      debugPrint('PlaySettingsProvider: setPlayMode failed — $e');
    }
  }

  Future<void> setReciter(int index) async {
    if (index < 0 ||
        index >= reciters.length ||
        _selectedReciterIndex == index) {
      return;
    }
    _selectedReciterIndex = index;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_reciterKey, index);
    } catch (e) {
      debugPrint('PlaySettingsProvider: setReciter failed — $e');
    }
  }

  Future<void> setShowTranslation(bool value) async {
    if (_showTranslation == value) return;
    _showTranslation = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_showTranslationKey, value);
    } catch (e) {
      debugPrint('PlaySettingsProvider: setShowTranslation failed — $e');
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    if (_playbackSpeed == speed) return;
    _playbackSpeed = speed;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_speedKey, speed);
    } catch (e) {
      debugPrint('PlaySettingsProvider: setPlaybackSpeed failed — $e');
    }
  }

  /// Cycles to the next preset speed and returns it.
  double cycleSpeed() {
    final idx = speedPresets.indexOf(_playbackSpeed);
    final next = speedPresets[(idx + 1) % speedPresets.length];
    setPlaybackSpeed(next);
    return next;
  }
}
