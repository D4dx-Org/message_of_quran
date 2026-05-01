import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class WakelockProvider extends ChangeNotifier {
  static const _key = 'keep_screen_on';

  bool _keepScreenOn = false;

  bool get keepScreenOn => _keepScreenOn;

  WakelockProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _keepScreenOn = prefs.getBool(_key) ?? false;
    if (_keepScreenOn) {
      await WakelockPlus.enable();
    }
    notifyListeners();
  }

  Future<void> toggleKeepScreenOn(bool value) async {
    if (_keepScreenOn == value) return;
    _keepScreenOn = value;

    if (_keepScreenOn) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _keepScreenOn);
    notifyListeners();
  }
}
