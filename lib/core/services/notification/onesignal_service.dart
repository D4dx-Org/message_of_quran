import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static const String _appId = '5ec1c668-b004-41a1-989f-c9a802c73466';

  /// Initialize OneSignal. Call this once from main() before runApp().
  static Future<void> initialize() async {
    // Enable verbose logging in debug mode only
    if (kDebugMode) {
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    }

    OneSignal.initialize(_appId);

    // Request push notification permission (with timeout to avoid blocking startup)
    try {
      await OneSignal.Notifications.requestPermission(false)
          .timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('⚠️ OneSignal: permission request timed out or failed — $e');
    }

    // Listen for notifications received while app is in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener(
      _onForegroundNotification,
    );

    // Listen for notification taps (both foreground and background)
    OneSignal.Notifications.addClickListener(_onNotificationClicked);

    // Listen for permission changes
    OneSignal.Notifications.addPermissionObserver(_onPermissionChanged);

    debugPrint('✅ OneSignal initialized');
  }

  /// Called when a notification is about to be shown while the app is in foreground.
  static void _onForegroundNotification(
    OSNotificationWillDisplayEvent event,
  ) {
    debugPrint(
      '📩 OneSignal: foreground notification received — ${event.notification.title}',
    );

    // Display the notification (default behaviour); remove this line to suppress it.
    event.notification.display();
  }

  /// Called when the user taps on a notification.
  static void _onNotificationClicked(OSNotificationClickEvent event) {
    debugPrint(
      '🔔 OneSignal: notification tapped — ${event.notification.title}',
    );

    // TODO: add navigation or deep-link logic here using event.notification.launchUrl
    // or event.notification.additionalData
  }

  /// Called when the notification permission status changes.
  static void _onPermissionChanged(bool permission) {
    debugPrint('🔔 OneSignal: notification permission changed → $permission');
  }

  // ──────────────────────────────────────────────
  // Helper methods you can call from anywhere in the app
  // ──────────────────────────────────────────────

  /// Log in an external user (e.g. after the user signs in).
  static void login(String externalUserId) {
    OneSignal.login(externalUserId);
    debugPrint('✅ OneSignal: logged in as $externalUserId');
  }

  /// Log out the current user.
  static void logout() {
    OneSignal.logout();
    debugPrint('✅ OneSignal: logged out');
  }

  /// Tag the user for segmentation (e.g. language, subscription tier).
  static void addTag(String key, String value) {
    OneSignal.User.addTagWithKey(key, value);
    debugPrint('✅ OneSignal: tag added — $key=$value');
  }

  /// Remove a tag.
  static void removeTag(String key) {
    OneSignal.User.removeTag(key);
    debugPrint('✅ OneSignal: tag removed — $key');
  }

  /// Opt the user in or out of push notifications at runtime.
  static void setPushOptIn(bool optIn) {
    if (optIn) {
      OneSignal.User.pushSubscription.optIn();
    } else {
      OneSignal.User.pushSubscription.optOut();
    }
    debugPrint('✅ OneSignal: push opt-in set to $optIn');
  }

  /// Subscribe to a topic/segment by tagging the user.
  static void subscribeToTopic(String topic) => addTag('topic_$topic', 'true');

  /// Get the current OneSignal push subscription ID.
  static String? get subscriptionId =>
      OneSignal.User.pushSubscription.id;
}
