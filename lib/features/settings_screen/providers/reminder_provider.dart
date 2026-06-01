import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/utils/platform_helper.dart';

class ReminderProvider extends ChangeNotifier {
  static const _enabledKey = 'daily_reminder_enabled';
  static const _hourKey = 'daily_reminder_hour';
  static const _minuteKey = 'daily_reminder_minute';
  static const int _notificationId = 1001;
  static const int _fridayNotificationId = 1002;
  static const _ayahOfTheDayRoute = 'ayah_of_the_day';
  static const _surahAlKahfRoute = 'surah_18';

  bool _isEnabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);

  bool get isEnabled => _isEnabled;
  TimeOfDay get time => _time;
  bool get isSupported => !PlatformHelper.isWeb;

  ReminderProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_enabledKey) ?? false;
    _time = TimeOfDay(
      hour: prefs.getInt(_hourKey) ?? 20,
      minute: prefs.getInt(_minuteKey) ?? 0,
    );
    if (!isSupported) {
      if (_isEnabled) {
        _isEnabled = false;
        await prefs.setBool(_enabledKey, false);
      }
      notifyListeners();
      return;
    }

    final notificationsAllowed =
        await AwesomeNotifications().isNotificationAllowed();
    if (notificationsAllowed) {
      // Request exact alarm permission (required on Android 12+ for precise scheduling)
      await AwesomeNotifications().requestPermissionToSendNotifications(
        permissions: [NotificationPermission.PreciseAlarms],
      );
      await _scheduleFridayReminder();
      if (_isEnabled) {
        await _scheduleReminder();
      }
    }
    notifyListeners();
  }

  /// Returns `true` if the toggle was successful, `false` if permission was
  /// denied and the reminder could not be enabled.
  Future<bool> toggleReminder(bool enabled) async {
    if (!isSupported) {
      return false;
    }
    if (_isEnabled == enabled) return true;

    if (enabled) {
      final allowed = await AwesomeNotifications().isNotificationAllowed();
      if (!allowed) {
        final granted = await AwesomeNotifications()
            .requestPermissionToSendNotifications();
        if (!granted) return false;
      }
      _isEnabled = true;
      await _scheduleFridayReminder();
      await _scheduleReminder();
    } else {
      _isEnabled = false;
      await _cancelReminder();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, _isEnabled);
    notifyListeners();
    return true;
  }

  Future<void> setTime(TimeOfDay newTime) async {
    if (_time == newTime) return;
    _time = newTime;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_hourKey, newTime.hour);
    await prefs.setInt(_minuteKey, newTime.minute);

    if (_isEnabled) {
      await _cancelReminder();
      await _scheduleReminder();
    }
    notifyListeners();
  }

  Future<void> _scheduleReminder() async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _notificationId,
          channelKey: 'daily_reminder',
          title: 'Today\'s Ayah is waiting for you! 📖',
          body: 'Tap to read and share today\'s verse',
          payload: {'route': _ayahOfTheDayRoute},
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar(
          hour: _time.hour,
          minute: _time.minute,
          second: 0,
          repeats: true,
          preciseAlarm: true,
        ),
      );
    } catch (e) {
      debugPrint('ReminderProvider: schedule error – $e');
    }
  }

  Future<void> _scheduleFridayReminder() async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: _fridayNotificationId,
          channelKey: 'daily_reminder',
          title: 'It\'s Friday',
          body: 'Read Surah Al-Kahf',
          payload: {'route': _surahAlKahfRoute},
          notificationLayout: NotificationLayout.Default,
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar(
          weekday: DateTime.friday,
          hour: 11,
          minute: 0,
          second: 0,
          repeats: true,
          preciseAlarm: true,
        ),
      );
    } catch (e) {
      debugPrint('ReminderProvider: Friday schedule error – $e');
    }
  }

  Future<void> _cancelReminder() async {
    try {
      await AwesomeNotifications().cancel(_notificationId);
    } catch (e) {
      debugPrint('ReminderProvider: cancel error – $e');
    }
  }
}
