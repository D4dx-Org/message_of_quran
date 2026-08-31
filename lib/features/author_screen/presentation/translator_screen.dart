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
import 'package:the_message_of_the_quran/features/author_screen/provider/translator_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/core/constants/api_constants.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> with RouteAware {
  bool? _lastMalayalam;
  ModalRoute<void>? _subscribedRoute;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<DatabaseReadyNotifier>().whenReady;
      if (!mounted) return;
      Provider.of<TranslatorProvider>(context, listen: false)
          .getAboutAuthorInfo();
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
    // This screen only ever shows the Malayalam translator's bio. If the
    // user switches the app language away from Malayalam while it's still
    // the visible screen, hop over to its English sibling route instead of
    // showing stale Malayalam content. A pushReplacement while this screen
    // is buried under another route (e.g. a Library page) would hijack that
    // route instead, so only act when this route is actually on top.
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    if (_lastMalayalam != isMalayalam) {
      _lastMalayalam = isMalayalam;
      if (!isMalayalam && route!.isCurrent) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.pushReplacement('/translator-en', extra: instantSwap);
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
    if (!isMalayalam) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.pushReplacement('/translator-en', extra: instantSwap);
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
        title: 'വിവർത്തകൻ',
      ),
      drawer: const CommonDrawer(),
      expandContentCard: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 0),
        child: Consumer<TranslatorProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading || dbLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (provider.aboutAuthorList.isEmpty) {
              return Center(
                child: SelectableText(
                  'വിവർത്തകനെ കുറിച്ചുള്ള വിവരങ്ങൾ ലഭ്യമല്ല.',
                  style: AppTextTheme.localizedBody(
                    isMalayalam: true,
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              );
            }
            final author = provider.aboutAuthorList.first;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (author.name != null && author.name!.isNotEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SelectableText(
                          author.name!,
                          textAlign: TextAlign.center,
                          style: AppTextTheme.localizedTitle(
                            isMalayalam: true,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: bodyColor,
                          ),
                        ),
                      ),
                    ),
                  BioWithFloatingImage(
                    imagePath: '${ApiConstants.imageCdnBaseUrl}/kc-saleem-photo.jpeg',
                    thumbnailPath: 'assets/images/kc-saleem-photo_thumb.jpeg',
                    bioText: (author.bio != null && author.bio!.isNotEmpty)
                        ? author.bio!
                            .split('\n')
                            .where((p) => p.trim().isNotEmpty)
                            .map((p) => p.trim())
                            .join('\n\n')
                        : '',
                    textStyle: AppTextTheme.localizedBody(
                      isMalayalam: true,
                      fontSize: 15,
                      color: bodyColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                     if (author.mobile != null && author.mobile!.isNotEmpty)
                    SelectableText(
                        author.mobile!,
                      style: AppTextTheme.popinsDefault(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: bodyColor,
                      ),
                    ),
                  if (author.email != null && author.email!.isNotEmpty)
                    SelectableText(
                      'E-mail: ${author.email!}',
                      style: AppTextTheme.popinsDefault(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: bodyColor,
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
