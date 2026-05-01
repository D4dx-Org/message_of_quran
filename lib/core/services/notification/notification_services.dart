// Add NotificationController class
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationController {
  Future<void> initializeNotifications() async {
    final notificationService = FlutterLocalNotificationsPlugin();

    try {
      // Initialize local notifications
      await notificationService.initialize(
        settings: const InitializationSettings(),
      );
      debugPrint('✅ Local notifications initialized');

      // Check if notifications are enabled (both system permission and app setting)
      final notificationsEnabled = await AwesomeNotifications()
          .isNotificationAllowed();
      debugPrint('📱 Notifications enabled: $notificationsEnabled');

      if (notificationsEnabled) {
        // We'll skip prayer time initialization here since we don't have context yet
        // Prayer times will be initialized properly in the NotificationSettingsScreen
        // when the user navigates to it, or in a widget that has access to context

        debugPrint(
          'ℹ️ Deferring prayer time initialization until context is available',
        );

        // Check and schedule Friday reminder if not already scheduled
        // final isFridayReminderScheduled = await notificationService
        //     .isNotificationScheduled(LocalNotificationService.fridayReminderId);
        // debugPrint(
        //   '📅 Friday reminder already scheduled: $isFridayReminderScheduled',
        // );

        // if (!isFridayReminderScheduled) {
        //   await notificationService.fridayReminder();
        //   debugPrint('✅ Friday reminder scheduled');
        // }
      } else {
        debugPrint('⚠️ Notifications are disabled, skipping scheduling');
      }

      // Set up notification action listeners
      AwesomeNotifications().setListeners(
        onActionReceivedMethod: NotificationController.onActionReceivedMethod,
        onNotificationCreatedMethod:
            NotificationController.onNotificationCreatedMethod,
        onNotificationDisplayedMethod:
            NotificationController.onNotificationDisplayedMethod,
        onDismissActionReceivedMethod:
            NotificationController.onDismissActionReceivedMethod,
      );
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
      // Consider how you want to handle notification initialization failures
    }
  }

  /// Use this method to detect when a new notification or a schedule is created
  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('onNotificationCreatedMethod');
  }

  /// Use this method to detect every time that a new notification is displayed
  @pragma("vm:entry-point")
  static Future<void> onNotificationDisplayedMethod(
    ReceivedNotification receivedNotification,
  ) async {
    debugPrint('onNotificationDisplayedMethod');
  }

  /// Use this method to detect if the user dismissed a notification
  @pragma("vm:entry-point")
  static Future<void> onDismissActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('onDismissActionReceivedMethod');
  }

  /// Use this method to detect when the user taps on a notification or action button
  @pragma("vm:entry-point")
  static Future<void> onActionReceivedMethod(
    ReceivedAction receivedAction,
  ) async {
    debugPrint('onActionReceivedMethod');
    // Delegate notification handling to LocalNotificationService
    // await LocalNotificationService.handleNotificationAction(
    //   receivedAction,
    //   navigatorKey.currentContext,
    // );
  }
}
