import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_message_of_the_quran/core/services/database/database_ready_notifier.dart';
import 'package:the_message_of_the_quran/features/author_screen/author_screen.dart';
import 'package:the_message_of_the_quran/features/author_screen/presentation/english_translator_screen.dart';
import 'package:the_message_of_the_quran/features/author_screen/presentation/translator_screen.dart';
import 'package:the_message_of_the_quran/features/ayah_of_the_day/presentation/ayah_of_the_day_screen.dart';
import 'package:the_message_of_the_quran/features/bookmark_screen/presentation/bookmark_screen.dart';
import 'package:the_message_of_the_quran/features/common_email/presentation/feedback_screen.dart';
import 'package:the_message_of_the_quran/features/contact_us_screen/presentation/contact_us_screen.dart';
import 'package:the_message_of_the_quran/features/force_update_screen/presentation/force_update_screen.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/home_screen.dart';
import 'package:the_message_of_the_quran/features/library/presentation/appendix_screen.dart';
import 'package:the_message_of_the_quran/features/library/presentation/foreword_screen.dart';
import 'package:the_message_of_the_quran/features/library/presentation/works_of_reference_screen.dart';
import 'package:the_message_of_the_quran/features/main_screen/presentation/main_screen.dart';
import 'package:the_message_of_the_quran/features/mushaf/screens/mushaf_landing_screen.dart';
import 'package:the_message_of_the_quran/features/mushaf/screens/mushaf_reader_screen.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/screens/add_progression_screen.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/screens/ayah_reading_screen.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/screens/progression_day_detail_screen.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/screens/progression_detail_screen.dart';
import 'package:the_message_of_the_quran/features/progression_tracker/screens/progression_tracker_screen.dart';
import 'package:the_message_of_the_quran/features/prostration_verses/presentation/prostration_verses_screen.dart';
import 'package:the_message_of_the_quran/features/splash_screen/presentation/splash_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>();

int? _intParam(Map<String, String> params, String key) =>
    int.tryParse(params[key] ?? '');

GoRouter buildAppRouter() {
  // go_router 8.0+ stopped syncing the browser URL on push()/pushReplacement()
  // by default (only go() does) — every context.push() call site in this app
  // was written expecting the pre-8.0 behavior (URL reflects the current
  // screen so refresh/deep-link work), so opt back into it here.
  GoRouter.optionURLReflectsImperativeAPIs = true;

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: kIsWeb ? '/' : '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/force-update',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ForceUpdateScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainScreen(shell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKey,
            routes: [
              GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookmarks',
                builder: (context, state) => const BookmarkScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/mushaf',
                builder: (context, state) => const MushafLandingScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/surah/:surahNumber',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final surahNumber = int.parse(state.pathParameters['surahNumber']!);
          final scrollToAyahId = _intParam(
            state.uri.queryParameters,
            'scrollToAyahId',
          );
          return SurahRouteResolver(
            surahNumber: surahNumber,
            scrollToAyahId: scrollToAyahId,
          );
        },
      ),
      GoRoute(
        path: '/mushaf-reader',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return MushafReaderScreen(
            initialPage: _intParam(q, 'page'),
            initialSurahNo: _intParam(q, 'surahNo'),
            initialAyaNo: _intParam(q, 'ayaNo'),
          );
        },
      ),
      GoRoute(
        path: '/author',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AuthorScreen(),
      ),
      GoRoute(
        path: '/translator',
        parentNavigatorKey: rootNavigatorKey,
        // No transition: switching the app language while on this page
        // pushReplacement()s to '/translator-en', which should read as an
        // instant content swap rather than a page navigation.
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: TranslatorScreen()),
      ),
      GoRoute(
        path: '/translator-en',
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: EnglishTranslatorScreen()),
      ),
      GoRoute(
        path: '/foreword',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ForewordScreen(),
      ),
      GoRoute(
        path: '/appendix',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AppendixScreen(
          initialAppendixNumber: _intParam(
            state.uri.queryParameters,
            'appendixNumber',
          ),
        ),
      ),
      GoRoute(
        path: '/works-of-reference',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const WorksOfReferenceScreen(),
      ),
      GoRoute(
        path: '/prostration-verses',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ProstrationVersesScreen(),
      ),
      GoRoute(
        path: '/feedback',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const FeedbackScreen(),
      ),
      GoRoute(
        path: '/contact-us',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ContactUsScreen(),
      ),
      GoRoute(
        path: '/ayah-of-the-day',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AyahOfTheDayScreen(),
      ),
      GoRoute(
        path: '/progression',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ProgressionTrackerScreen(),
      ),
      GoRoute(
        path: '/progression/add',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AddProgressionScreen(),
      ),
      GoRoute(
        path: '/progression/:progressionId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ProgressionDetailScreen(
          progressionId: int.parse(state.pathParameters['progressionId']!),
        ),
      ),
      GoRoute(
        path: '/progression/:progressionId/day/:dayId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => ProgressionDayDetailScreen(
          progressionId: int.parse(state.pathParameters['progressionId']!),
          dayId: int.parse(state.pathParameters['dayId']!),
        ),
      ),
      GoRoute(
        path: '/progression/:progressionId/day/:dayId/reading',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => AyahReadingScreen(
          progressionId: int.parse(state.pathParameters['progressionId']!),
          dayId: int.parse(state.pathParameters['dayId']!),
        ),
      ),
    ],
  );
}

/// Resolves [surahNumber] into [SurahProvider] before rendering
/// [SurahScreen] — replaces the old per-callsite `indexWhere` + `assignIndex`
/// boilerplate with a single lookup done inside the route.
class SurahRouteResolver extends StatefulWidget {
  const SurahRouteResolver({
    super.key,
    required this.surahNumber,
    this.scrollToAyahId,
  });

  final int surahNumber;
  final int? scrollToAyahId;

  @override
  State<SurahRouteResolver> createState() => _SurahRouteResolverState();
}

class _SurahRouteResolverState extends State<SurahRouteResolver> {
  late Future<void> _resolveFuture;

  @override
  void initState() {
    super.initState();
    _resolveFuture = _resolve();
  }

  @override
  void didUpdateWidget(covariant SurahRouteResolver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.surahNumber != widget.surahNumber) {
      // go_router reuses this element (same Page key) for surah-to-surah
      // navigation, so this runs inside didUpdateWidget — which fires while
      // the framework's build phase is still locked. selectSurahByNumber()
      // calls notifyListeners() synchronously once surahList is already
      // loaded, which would throw "setState() called during build" if
      // called from here directly. Defer to after the frame, same fix
      // SurahProvider's own constructor already applies to loadBookmarks().
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _resolveFuture = _resolve());
      });
    }
  }

  Future<void> _resolve() async {
    await context.read<DatabaseReadyNotifier>().whenReady;
    if (!mounted) return;
    final surahProvider = context.read<SurahProvider>();
    // On a direct/refresh load of this route, MainScreen never mounts (this
    // route sits outside the StatefulShellRoute), so SurahProvider's language
    // flag stays at its default instead of being synced from the persisted
    // setting. Sync it here before fetching, or translations load in the
    // wrong language even though the UI chrome (surah name, dropdown) reads
    // LanguageProvider directly and shows the correct one.
    // Read SharedPreferences directly rather than via LanguageProvider:
    // LanguageProvider's own init is async and may not have finished
    // resolving yet at this point, which would just re-introduce the race.
    final prefs = await SharedPreferences.getInstance();
    final isMalayalam = (prefs.getString('app_language') ?? 'en') == 'ml';
    if (surahProvider.isMalayalam != isMalayalam) {
      await surahProvider.setMalayalam(isMalayalam);
    }
    if (!mounted) return;
    return surahProvider.selectSurahByNumber(widget.surahNumber);
  }

  void _retry() {
    context.read<DatabaseReadyNotifier>().retry();
    setState(() => _resolveFuture = _resolve());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _resolveFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load this surah.'),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _retry, child: const Text('Retry')),
                ],
              ),
            ),
          );
        }
        return SurahScreen(scrollToAyahId: widget.scrollToAyahId);
      },
    );
  }
}
