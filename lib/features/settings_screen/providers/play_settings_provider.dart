import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PlayMode { singleBlock, continuous }

class ReciterInfo {
  final String name;
  final String folderName;
  const ReciterInfo({required this.name, required this.folderName});
}

class PlaySettingsProvider extends ChangeNotifier {
  // v2 key — old 'play_mode' stored singleBlock(0) as default, so a fresh
  // key ensures all users start with continuous until they explicitly change it.
  static const _playModeKey = 'play_mode_v2';
  static const _reciterKey = 'reciter_index';
  static const _showTranslationKey = 'show_translation';
  static const _speedKey = 'playback_speed';
  static const _verticalScrollKey = 'vertical_scroll';

  static const List<double> speedPresets = [0.75, 1.0, 1.25, 1.5];

  static const List<ReciterInfo> reciters = [
    ReciterInfo(name: 'Mishary Rashid Alafasy', folderName: 'Alafasy_128kbps'),
    ReciterInfo(
        name: 'Mahmoud Khalil Al-Husary', folderName: 'Husary_128kbps'),
    ReciterInfo(
        name: 'Muhammad Siddiq Al-Minshawi (Mujawwad)',
        folderName: 'Minshawy_Mujawwad_192kbps'),
    ReciterInfo(
        name: 'Abdul Basit Abdul Samad (Mujawwad)',
        folderName: 'Abdul_Basit_Mujawwad_128kbps'),
    ReciterInfo(name: 'Saad Al-Ghamdi', folderName: 'Ghamadi_40kbps'),
    ReciterInfo(
        name: 'Ahmed ibn Ali Al-Ajamy',
        folderName: 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net'),
  ];

  PlayMode _playMode = PlayMode.continuous;
  int _selectedReciterIndex = 0;
  bool _showTranslation = true;
  double _playbackSpeed = 1.0;
  bool _verticalScroll = true;

  PlayMode get playMode => _playMode;
  int get selectedReciterIndex => _selectedReciterIndex;
  ReciterInfo get selectedReciter => reciters[_selectedReciterIndex];
  bool get showTranslation => _showTranslation;
  double get playbackSpeed => _playbackSpeed;
  bool get verticalScroll => _verticalScroll;

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
      _verticalScroll = prefs.getBool(_verticalScrollKey) ?? true;
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

  Future<void> setVerticalScroll(bool value) async {
    if (_verticalScroll == value) return;
    _verticalScroll = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_verticalScrollKey, value);
    } catch (e) {
      debugPrint('PlaySettingsProvider: setVerticalScroll failed — $e');
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
