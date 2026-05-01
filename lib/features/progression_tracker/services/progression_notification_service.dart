import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';

class ProgressionNotificationService {
  static const String channelKey = 'progression_reminder';

  /// Schedule weekly recurring reminders for a progression.
  /// [progressionId] is used as the base for notification IDs.
  /// [time] format: "HH:mm" (24h)
  /// [days] list of day names: ["Mon", "Tue", ...]
  /// [surahName] for notification body text.
  static Future<void> scheduleReminders({
    required int progressionId,
    required String time,
    required List<String> days,
    required String surahName,
  }) async {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    const dayMap = {
      'Mon': 1,
      'Tue': 2,
      'Wed': 3,
      'Thu': 4,
      'Fri': 5,
      'Sat': 6,
      'Sun': 7,
    };

    for (final dayName in days) {
      final weekday = dayMap[dayName];
      if (weekday == null) continue;

      final notificationId = _notificationId(progressionId, weekday);

      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: notificationId,
          channelKey: channelKey,
          title: 'Quran Progression Reminder',
          body: 'Time to continue learning $surahName!',
          notificationLayout: NotificationLayout.Default,
          payload: {'progression_id': '$progressionId'},
        ),
        schedule: NotificationCalendar(
          weekday: weekday,
          hour: hour,
          minute: minute,
          second: 0,
          millisecond: 0,
          repeats: true,
          preciseAlarm: true,
        ),
      );
    }
  }

  /// Cancel all reminders for a given progression.
  static Future<void> cancelReminders(int progressionId) async {
    for (int weekday = 1; weekday <= 7; weekday++) {
      await AwesomeNotifications().cancel(_notificationId(progressionId, weekday));
    }
  }

  /// Update reminders: cancel old ones and schedule new.
  static Future<void> updateReminders({
    required int progressionId,
    required String time,
    required List<String> days,
    required String surahName,
  }) async {
    await cancelReminders(progressionId);
    await scheduleReminders(
      progressionId: progressionId,
      time: time,
      days: days,
      surahName: surahName,
    );
  }

  /// Generate a unique notification ID from progressionId and weekday.
  /// Uses a deterministic scheme: progressionId * 10 + weekday.
  static int _notificationId(int progressionId, int weekday) {
    return progressionId * 10 + weekday;
  }

  /// Format time and days for display.
  /// Returns e.g. "8:00 AM on Mon, Tue, Wed, Thu, Fri, Sat, Sun"
  static String formatSchedule(String time, List<String> days) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    final displayMinute = minute.toString().padLeft(2, '0');
    final timeStr = '$displayHour:$displayMinute $period';
    return '$timeStr on ${days.join(', ')}';
  }

  /// Parse a display time like "8:00 AM" to 24h format "08:00"
  static String parseDisplayTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Parse stored "HH:mm" to TimeOfDay
  static TimeOfDay parseStoredTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}
