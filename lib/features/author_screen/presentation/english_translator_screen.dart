import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/core/widgets/bio_with_floating_image.dart';
import 'package:the_message_of_the_quran/core/routing/app_router.dart';
import 'package:the_message_of_the_quran/core/services/database/database_ready_notifier.dart';
import 'package:the_message_of_the_quran/features/author_screen/provider/english_translator_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';

class EnglishTranslatorScreen extends StatefulWidget {
  const EnglishTranslatorScreen({super.key});
  @override
  State<EnglishTranslatorScreen> createState() =>
      _EnglishTranslatorScreenState();
}

class _EnglishTranslatorScreenState extends State<EnglishTranslatorScreen>
    with RouteAware {
  bool? _lastMalayalam;
  ModalRoute<void>? _subscribedRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<DatabaseReadyNotifier>().whenReady;
      if (!mounted) return;
      Provider.of<EnglishTranslatorProvider>(context, listen: false)
          .getTranslatorInfo();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _subscribedRoute) {
      if (_subscribedRoute != null) appRouteObserver.unsubscribe(this);
      if (route != null) appRouteObserver.subscribe(this, route);
      _subscribedRoute = route;
    }
    // This screen only ever shows the English translator's bio. If the
    // user switches the app language to Malayalam while it's still the
    // visible screen, hop over to its Malayalam sibling route instead of
    // showing stale English content. A pushReplacement while this screen
    // is buried under another route (e.g. a Library page) would hijack that
    // route instead, so only act when this route is actually on top.
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    if (_lastMalayalam != isMalayalam) {
      _lastMalayalam = isMalayalam;
      if (isMalayalam && route!.isCurrent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.pushReplacement('/translator', extra: instantSwap);
          }
        });
      }
    }
  }

  @override
  void didPopNext() {
    // Another route that was covering this screen got popped, so this
    // screen is visible again — re-check in case the language changed
    // while it was buried.
    final isMalayalam = context.read<LanguageProvider>().isMalayalam;
    if (isMalayalam) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushReplacement('/translator', extra: instantSwap);
        }
      });
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor = isDark ? Colors.white70 : Colors.black87;
    final dbLoading =
        context.watch<DatabaseReadyNotifier>().status == DbInitStatus.loading;

    return BaseScreenLayout(
      appBar: CommonAppBar.homeAppBar(
        context,
        showOrnament: false,
        title: 'Translator',
      ),
      expandContentCard: false,
      drawer: const CommonDrawer(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
        child: Consumer<EnglishTranslatorProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading || dbLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.translatorList.isEmpty) {
              return Center(
                child: SelectableText(
                  'No translator information available.',
                  style: AppTextTheme.popinsDefault(
                      fontSize: 14, color: Colors.grey),
                ),
              );
            }
            final translator = provider.translatorList.first;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (translator.name != null && translator.name!.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SelectableText(
                          translator.name!,
                          textAlign: TextAlign.center,
                          style: AppTextTheme.popinsDefault(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: bodyColor,
                          ),
                        ),
                      ),
                    ),
                  BioWithFloatingImage(
                    imagePath: 'assets/images/kc-saleem.png',
                    thumbnailPath: 'assets/images/kc-saleem_thumb.png',
                    bioText: (translator.bio != null &&
                            translator.bio!.isNotEmpty)
                        ? translator.bio!
                            .split('\n')
                            .where((p) => p.trim().isNotEmpty)
                            .map((p) => p.trim())
                            .join('\n\n')
                        : '',
                    textStyle:
                        AppTextTheme.popinsDefault(fontSize: 15, color: bodyColor),
                  ),
                  const SizedBox(height: 16),
                  if (translator.address != null &&
                      translator.address!.isNotEmpty)
                    SelectableText(
                      'Address: ${translator.address!}',
                      style: AppTextTheme.popinsDefault(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: bodyColor),
                    ),
                  if (translator.email != null && translator.email!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SelectableText(
                        'Email: ${translator.email!}',
                        style: AppTextTheme.popinsDefault(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: bodyColor),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
