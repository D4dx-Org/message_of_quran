import 'dart:async';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/services/audio_handler.dart';
import 'package:the_message_of_the_quran/core/services/database/database_helper.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/features/main_screen/providers/home_provider.dart';
import 'package:the_message_of_the_quran/features/main_screen/presentation/main_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/font_size_changer_provider.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/splash_screen.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/widgets/splash_screen_layout.dart';
import 'package:the_message_of_the_quran/features/splash_screen/providers/version_check_provider.dart';
import 'package:the_message_of_the_quran/features/about_screen/provider/about_providers.dart';
import 'package:the_message_of_the_quran/features/contact_us_screen/presentation/provider/contact_provider.dart';
import 'package:the_message_of_the_quran/features/author_screen/provider/author_provider.dart';
import 'package:the_message_of_the_quran/features/author_screen/provider/translator_provider.dart';
import 'package:the_message_of_the_quran/features/author_screen/provider/translator_note_provider.dart';
import 'package:the_message_of_the_quran/features/author_screen/provider/english_translator_provider.dart';
import 'package:the_message_of_the_quran/features/help_screen/provider/help_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/play_settings_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/audio_provider.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/last_read_provider.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/reading_progress_provider.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/juz_hizb_provider.dart';
import 'package:the_message_of_the_quran/core/services/notification/onesignal_service.dart';
import 'package:the_message_of_the_quran/features/mushaf/services/mushaf_download_manager.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/provider/progression_tracker_provider.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/provider/progression_detail_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/reminder_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/tajweed_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/wakelock_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/ayah_of_the_day/provider/ayah_of_the_day_provider.dart';
import 'package:the_message_of_the_quran/core/services/notification/notification_services.dart';
import 'package:the_message_of_the_quran/features/ayah_of_the_day/presentation/ayah_of_the_day_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';

/// Global navigator key used to navigate from notification taps.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Stores a pending route when a notification is tapped before the navigator
/// is ready (e.g. app cold-started from notification).
String? pendingNotificationRoute;

const String ayahOfTheDayNotificationRoute = 'ayah_of_the_day';
const String surahAlKahfNotificationRoute = 'surah_18';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Show a simple error widget in release mode instead of the red error screen.
  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return const SizedBox.shrink();
    };
  }

  // Catch Flutter framework errors.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  // Catch async errors that escape the Flutter framework.
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught async error: $error\n$stack');
    return true;
  };

  runApp(const AppBootstrap());
}

Future<void> _initializeAppServices() async {
  debugPrint('Bootstrap: initializing database services');
  await DatabaseHelper.initializeServices().timeout(
    const Duration(seconds: 20),
    onTimeout: () => throw TimeoutException(
      'Database initialization timed out.',
    ),
  );

  debugPrint('Bootstrap: initializing audio services');
  if (kIsWeb) {
    audioHandler ??= QuranAudioHandler();
    return;
  }

  audioHandler = await AudioService.init(
    builder: () => QuranAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId:
          'com.d4dx.the_message_of_the_quran.audio',
      androidNotificationChannelName: 'Quran Audio',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  ).timeout(
    const Duration(seconds: 10),
    onTimeout: () => throw TimeoutException(
      'Audio service initialization timed out.',
    ),
  );

  debugPrint('Bootstrap: initializing mobile-only services');
  await OneSignalService.initialize();
  await MushafDownloadManager.instance.syncWithPersistedState();

  await AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'mushaf_download',
        channelName: 'Mushaf Download',
        channelDescription: 'Shows Mushaf font download progress',
        importance: NotificationImportance.Low,
        enableVibration: false,
        playSound: false,
        onlyAlertOnce: true,
      ),
      NotificationChannel(
        channelKey: 'daily_reminder',
        channelName: 'Daily Reminder',
        channelDescription: 'Daily Quran reading reminders',
        importance: NotificationImportance.High,
        enableVibration: true,
        playSound: true,
      ),
      NotificationChannel(
        channelKey: 'progression_reminder',
        channelName: 'Progression Reminder',
        channelDescription: 'Quran progression learning reminders',
        importance: NotificationImportance.High,
        enableVibration: true,
        playSound: true,
      ),
    ],
    debug: false,
  );

  AwesomeNotifications().setListeners(
    onActionReceivedMethod: _onNotificationTap,
    onNotificationCreatedMethod:
        NotificationController.onNotificationCreatedMethod,
    onNotificationDisplayedMethod:
        NotificationController.onNotificationDisplayedMethod,
    onDismissActionReceivedMethod:
        NotificationController.onDismissActionReceivedMethod,
  );

  final initialAction = await AwesomeNotifications()
      .getInitialNotificationAction(removeFromActionEvents: false);
  if (initialAction != null) {
    await _onNotificationTap(initialAction);
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late Future<void> _bootstrapFuture;

  @override
  void initState() {
    super.initState();
    _bootstrapFuture = _initializeAppServices();
  }

  void _retry() {
    setState(() {
      _bootstrapFuture = _initializeAppServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _bootstrapFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _BootstrapLoadingApp();
        }
        if (snapshot.hasError) {
          return _BootstrapErrorApp(
            error: snapshot.error,
            onRetry: _retry,
          );
        }
        return const MyApp();
      },
    );
  }
}

class _BootstrapLoadingApp extends StatelessWidget {
  const _BootstrapLoadingApp();

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: SplashScreenLayout()),
    );
  }
}

class _BootstrapErrorApp extends StatelessWidget {
  const _BootstrapErrorApp({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final details = error?.toString() ?? 'Unknown startup error';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'The app could not finish starting.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      details,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

@pragma("vm:entry-point")
Future<void> _onNotificationTap(ReceivedAction receivedAction) async {
  final targetRoute =
      receivedAction.payload?['route'] ??
      (receivedAction.channelKey == 'daily_reminder'
          ? ayahOfTheDayNotificationRoute
          : null);
  if (targetRoute == null) {
    return;
  }

  final handled = await handleNotificationRoute(targetRoute);
  if (!handled) {
    pendingNotificationRoute = targetRoute;
  }
}

Future<bool> handleNotificationRoute(String route) async {
  final nav = navigatorKey.currentState;
  final context = navigatorKey.currentContext;
  if (nav == null || context == null) {
    return false;
  }

  if (route == ayahOfTheDayNotificationRoute) {
    nav.push(MaterialPageRoute(builder: (_) => const AyahOfTheDayScreen()));
    return true;
  }

  if (route == surahAlKahfNotificationRoute) {
    final surahProv = Provider.of<SurahProvider>(context, listen: false);
    if (surahProv.surahList.isEmpty) await surahProv.getAllSurah();
    final idx = surahProv.surahList.indexWhere((s) => s.surahNumber == 18);
    if (idx < 0) return false;
    surahProv.assignIndex(idx);
    nav.push(MaterialPageRoute(builder: (_) => const SurahScreen()));
    return true;
  }

  return false;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => HomeProvider()),
        ChangeNotifierProvider(create: (context) => SurahProvider()),
        ChangeNotifierProvider(create: (context) => FontSizeChangerProvider()),
        ChangeNotifierProvider(create: (context) => VersionCheckProvider()),
        ChangeNotifierProvider(create: (context) => AboutProvider()),
        ChangeNotifierProvider(create: (context) => ContactProvider()),
        ChangeNotifierProvider(create: (context) => HelpProvider()),
        ChangeNotifierProvider(create: (context) => AuthorProvider()),
        ChangeNotifierProvider(create: (context) => TranslatorProvider()),
        ChangeNotifierProvider(create: (context) => TranslatorNoteProvider()),
        ChangeNotifierProvider(create: (context) => EnglishTranslatorProvider()),
        ChangeNotifierProvider(create: (context) => PlaySettingsProvider()),
        ChangeNotifierProvider(create: (context) => TajweedProvider()),
        ChangeNotifierProvider(create: (context) => ReminderProvider()),
        ChangeNotifierProvider(create: (context) => WakelockProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => AyahOfTheDayProvider()),
        ChangeNotifierProxyProvider2<SurahProvider, PlaySettingsProvider, AudioProvider>(
          create: (context) => AudioProvider(audioHandler!),
          update: (context, surahProvider, playSettingsProvider, audioProvider) {
            final provider = audioProvider ?? AudioProvider(audioHandler!);
            provider.attachDependencies(
              surahProvider: surahProvider,
              playSettings: playSettingsProvider,
            );
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (context) => LastReadProvider()),
        ChangeNotifierProvider(create: (context) => ReadingProgressProvider()),
        ChangeNotifierProvider(create: (context) => JuzHizbProvider()),
        ChangeNotifierProvider(create: (context) => ProgressionTrackerProvider()),
        ChangeNotifierProvider(create: (context) => ProgressionDetailProvider()),
        ChangeNotifierProvider<MushafDownloadManager>(
          create: (_) => MushafDownloadManager.instance,
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, value, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            title: 'Quran Asad Malayalam',
            showPerformanceOverlay: false,
            debugShowCheckedModeBanner: false,
            theme: value.lightTheme,
            darkTheme: value.darkTheme,
            themeMode: value.themeMode,
            home: kIsWeb ? MainScreen() : SplashScreen(),
            builder: (context, child) {
              var data = MediaQuery.of(context);
              final view = View.of(context);
              final physicalWidth = view.physicalSize.width;

              // Compute the device's "default" logical width from physical resolution.
              // Standard Android density: FHD(1080px)→2.75, QHD(1440px)→3.5, HD(720px)→2.0
              final double referenceDpr;
              if (physicalWidth >= 1260) {
                referenceDpr = 3.5;
              } else if (physicalWidth >= 900) {
                referenceDpr = 2.75;
              } else {
                referenceDpr = 2.0;
              }
              final double referenceWidth = physicalWidth / referenceDpr;

              if (data.size.width < referenceWidth - 1.0) {
                final double scale = data.size.width / referenceWidth;
                final double invScale = 1.0 / scale;
                final double referenceHeight = data.size.height * invScale;

                data = data.copyWith(
                  size: Size(referenceWidth, referenceHeight),
                  padding: EdgeInsets.only(
                    left: data.padding.left * invScale,
                    top: data.padding.top * invScale,
                    right: data.padding.right * invScale,
                    bottom: data.padding.bottom * invScale,
                  ),
                  viewPadding: EdgeInsets.only(
                    left: data.viewPadding.left * invScale,
                    top: data.viewPadding.top * invScale,
                    right: data.viewPadding.right * invScale,
                    bottom: data.viewPadding.bottom * invScale,
                  ),
                  viewInsets: EdgeInsets.only(
                    left: data.viewInsets.left * invScale,
                    top: data.viewInsets.top * invScale,
                    right: data.viewInsets.right * invScale,
                    bottom: data.viewInsets.bottom * invScale,
                  ),
                  textScaler: TextScaler.noScaling,
                );

                return MediaQuery(
                  data: data,
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: referenceWidth,
                      height: referenceHeight,
                      child: child!,
                    ),
                  ),
                );
              }

              return MediaQuery(
                data: data.copyWith(textScaler: TextScaler.noScaling),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
