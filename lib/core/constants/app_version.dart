import 'package:package_info_plus/package_info_plus.dart';

/// The running app's version, read from the build rather than kept by hand.
///
/// It used to be a string constant beside the other app constants, which drifts
/// the moment pubspec.yaml is bumped and nobody remembers to edit it too — it
/// had reached 1.0.13 while the app shipped as 1.0.15, and the drawer showed
/// that stale number to users. Reading it from the package means it cannot go
/// out of step with what was actually built.
class AppVersion {
  AppVersion._();

  static String _version = '';

  /// Empty until [load] completes, so callers should tolerate a blank label
  /// for the first moments of a cold start.
  static String get current => _version;

  static Future<void> load() async {
    final info = await PackageInfo.fromPlatform();
    _version = info.version;
  }
}
