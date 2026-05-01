import 'package:shared_preferences/shared_preferences.dart';

/// Persists Mushaf font-pack install state across app sessions.
class MushafInstallState {
  MushafInstallState._();

  static final MushafInstallState instance = MushafInstallState._();

  static const _kInstalled = 'mushaf_full_fonts_installed';
  static const _kVersion = 'mushaf_font_pack_version';
  static const _kInProgress = 'mushaf_install_in_progress';
  static const _kLastPage = 'mushaf_last_open_page';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<bool> get isFullFontsInstalled async =>
      (await _prefs).getBool(_kInstalled) ?? false;

  Future<void> setFullFontsInstalled({required bool value}) async {
    final p = await _prefs;
    await p.setBool(_kInstalled, value);
    if (value) await p.setBool(_kInProgress, false);
  }

  Future<bool> get isInstallInProgress async =>
      (await _prefs).getBool(_kInProgress) ?? false;

  Future<void> setInstallInProgress(bool value) async =>
      (await _prefs).setBool(_kInProgress, value);

  Future<int> get lastOpenPage async => (await _prefs).getInt(_kLastPage) ?? 1;

  Future<void> saveLastOpenPage(int page) async =>
      (await _prefs).setInt(_kLastPage, page);

  Future<String> get fontPackVersion async =>
      (await _prefs).getString(_kVersion) ?? '';

  Future<void> setFontPackVersion(String version) async =>
      (await _prefs).setString(_kVersion, version);

  Future<void> recoverFromInterrupted() async {
    if (await isInstallInProgress && !(await isFullFontsInstalled)) {
      await setInstallInProgress(false);
    }
  }
}
