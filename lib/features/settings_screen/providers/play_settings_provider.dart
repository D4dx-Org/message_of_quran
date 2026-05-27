import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';

enum PlayMode { singleBlock, continuous }

enum ReciterAudioSourceKind { everyAyah, customPerAyah }

class ReciterAudioSource {
  final ReciterAudioSourceKind kind;
  final String reciterPath;
  final String? baseUrl;

  const ReciterAudioSource.everyAyah(this.reciterPath)
    : kind = ReciterAudioSourceKind.everyAyah,
      baseUrl = null;

  const ReciterAudioSource.customPerAyah({
    required this.reciterPath,
    required this.baseUrl,
  }) : kind = ReciterAudioSourceKind.customPerAyah;

  bool get isConfigured {
    if (kind == ReciterAudioSourceKind.everyAyah) {
      return true;
    }
    return _normalizedBaseUrl(baseUrl).isNotEmpty;
  }

  String? buildAyahUrl(int surahNumber, int ayahId) {
    final resolvedBaseUrl = switch (kind) {
      ReciterAudioSourceKind.everyAyah => ApiConstants.everyAyahAudioBaseUrl,
      ReciterAudioSourceKind.customPerAyah => _normalizedBaseUrl(baseUrl),
    };
    if (resolvedBaseUrl.isEmpty) {
      return null;
    }

    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahId.toString().padLeft(3, '0');
    return '$resolvedBaseUrl/$reciterPath/$surah$ayah.mp3';
  }

  static String _normalizedBaseUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}

class ReciterInfo {
  final String name;
  final ReciterAudioSource audioSource;

  const ReciterInfo({required this.name, required this.audioSource});

  String get folderName => audioSource.reciterPath;
}

class PlaySettingsProvider extends ChangeNotifier {
  // v2 key — old 'play_mode' stored singleBlock(0) as default, so a fresh
  // key ensures all users start with continuous until they explicitly change it.
  static const _playModeKey = 'play_mode_v2';
  static const _reciterKey = 'reciter_index';
  static const _showTranslationKey = 'show_translation';
  static const _speedKey = 'playback_speed';

  static const List<double> speedPresets = [0.5, 1.0, 1.5, 2.0];

  static const List<ReciterInfo> reciters = [
    ReciterInfo(
        name: 'Abdul Basit Abdul Samad (Mujawwad)',
        audioSource: ReciterAudioSource.everyAyah(
          'Abdul_Basit_Mujawwad_128kbps',
        )),
    ReciterInfo(
        name: 'Abdurrahmaan As-Sudais',
        audioSource: ReciterAudioSource.everyAyah(
          'Abdurrahmaan_As-Sudais_192kbps',
        )),
    ReciterInfo(
        name: "Sa'ud Ash-Shuraym",
        audioSource: ReciterAudioSource.everyAyah(
          'Saood_ash-Shuraym_128kbps',
        )),
    ReciterInfo(
        name: 'Abdulrahman Al-Ossi',
        audioSource: ReciterAudioSource.customPerAyah(
          reciterPath: 'Abdulrahman_Al-Ossi_128kbps',
          baseUrl: ApiConstants.abdulrahmanAlOssiAudioBaseUrl,
        )),
    ReciterInfo(
        name: 'Abdullah Basfar',
        audioSource: ReciterAudioSource.everyAyah('Abdullah_Basfar_192kbps')),
    ReciterInfo(
        name: 'Ahmed ibn Ali Al-Ajamy',
        audioSource: ReciterAudioSource.everyAyah(
          'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net',
        )),
    ReciterInfo(
        name: 'Ali Jaber',
        audioSource: ReciterAudioSource.everyAyah('Ali_Jaber_64kbps')),
    ReciterInfo(
        name: 'Fares Abbad',
        audioSource: ReciterAudioSource.everyAyah('Fares_Abbad_64kbps')),
    ReciterInfo(
        name: 'Muhsin Al Qasim',
        audioSource: ReciterAudioSource.everyAyah('Muhsin_Al_Qasim_192kbps')),
    ReciterInfo(
        name: 'Nasser Alqatami',
        audioSource: ReciterAudioSource.everyAyah('Nasser_Alqatami_128kbps')),
    ReciterInfo(
        name: 'Abdullah Awwaad Al-Juhayni',
        audioSource: ReciterAudioSource.everyAyah(
          'Abdullaah_3awwaad_Al-Juhaynee_128kbps',
        )),
    ReciterInfo(
        name: 'Mahmoud Khalil Al-Husary',
        audioSource: ReciterAudioSource.everyAyah('Husary_128kbps')),
    ReciterInfo(
        name: 'Muhammad Siddiq Al-Minshawi (Mujawwad)',
        audioSource: ReciterAudioSource.everyAyah(
          'Minshawy_Mujawwad_192kbps',
        )),
    ReciterInfo(
        name: 'Saad Al-Ghamdi',
        audioSource: ReciterAudioSource.everyAyah('Ghamadi_40kbps')),
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

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeIndex = prefs.getInt(_playModeKey) ?? PlayMode.continuous.index;
      _playMode =
          PlayMode.values[modeIndex.clamp(0, PlayMode.values.length - 1)];
      _selectedReciterIndex =
          (prefs.getInt(_reciterKey) ?? 0).clamp(0, reciters.length - 1);
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
