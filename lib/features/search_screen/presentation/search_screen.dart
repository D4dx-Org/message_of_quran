import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/interpretation_search_result_model.dart';
import 'package:the_message_of_the_quran/core/models/verse_search_result_model.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/search_screen/widgets/interpretation_search_result_card.dart';
import 'package:the_message_of_the_quran/features/search_screen/widgets/verse_search_result_card.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  void initState() {
    super.initState();
    // Clear any stale search state so each fresh open starts clean.
    // This does NOT run when returning from SurahScreen (same instance resumes).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<SurahProvider>(context, listen: false).clear();
      }
    });
  }

  bool _useDesktopWebLayout(BuildContext context) {
    return kIsWeb;
  }

  // ─── Search field ────────────────────────────────────────────────────────

  Widget _buildSearchField(
    BuildContext context,
    SurahProvider controller,
    bool isMalayalam,
  ) {
    return SearchBar(
      trailing: [
        IconButton(
          onPressed: controller.clear,
          icon: const Icon(Icons.close),
        ),
      ],
      onChanged: (_) => controller.searchWithDebounce(),
      controller: controller.searchController,
      hintText: isMalayalam
          ? 'സൂറത്ത്, ആയത്ത്, ഫുട്ട്നോട്ട് തിരയുക...'
          : 'Search surahs, verses or interpretations...',
    );
  }

  // ─── Navigation helpers ──────────────────────────────────────────────────

  void _openSurahResult(
    BuildContext context,
    SurahProvider controller,
    int index,
  ) {
    final surah = controller.searchList[index];
    final idx = controller.surahList
        .indexWhere((s) => s.surahNumber == surah.surahNumber);
    if (idx < 0) return;
    controller.assignIndex(idx);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SurahScreen(showSearchIcon: false)),
    );
  }

  void _openVerseResult(
    BuildContext context,
    SurahProvider controller,
    VerseSearchResultModel result,
  ) {
    final idx = controller.surahList
        .indexWhere((s) => s.surahNumber == result.surahNumber);
    if (idx < 0) return;
    controller.assignIndex(idx);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahScreen(scrollToAyahId: result.verseNumber, showSearchIcon: false),
      ),
    );
  }

  void _openInterpretationResult(
    BuildContext context,
    SurahProvider controller,
    InterpretationSearchResultModel result,
  ) {
    if (result.surahNumber == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Surah context unavailable for this footnote.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    final idx = controller.surahList
        .indexWhere((s) => s.surahNumber == result.surahNumber);
    if (idx < 0) return;
    controller.assignIndex(idx);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahScreen(
          scrollToAyahId: result.verseNumber > 0 ? result.verseNumber : null,
          openInterpretationNumber:
              result.verseNumber > 0 ? result.verseNumber : null,
          showSearchIcon: false,
        ),
      ),
    );
  }

  // ─── Section header ──────────────────────────────────────────────────────

  Widget _buildSectionHeader(
    BuildContext context,
    String label,
    String countLabel,
    bool isMalayalam,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? Colors.white : Theme.of(context).colorScheme.primary;
    final secondaryColor = isDark ? Colors.white70 : Colors.grey[600]!;
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextTheme.localizedLabel(
              isMalayalam: isMalayalam,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            countLabel,
            style: AppTextTheme.localizedBody(
              isMalayalam: isMalayalam,
              fontSize: 12,
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Mobile results ──────────────────────────────────────────────────────

  Widget _buildMobileResults(BuildContext context, SurahProvider controller) {
    return Consumer<SurahProvider>(
      builder: (context, value, child) {
        final isMalayalam = context.watch<LanguageProvider>().isMalayalam;

        final hasSurahs = value.searchList.isNotEmpty;
        final hasVerses = value.verseSearchResults.isNotEmpty;
        final hasInterps = value.interpretationSearchResults.isNotEmpty;
        final hasAny = hasSurahs || hasVerses || hasInterps;

        if (!value.isSearched && !value.isSearchingContent) {
          return Expanded(
            child: Center(
              child: Text(
                isMalayalam ? 'തിരഞ്ഞ് ഫലം കാണൂ' : 'Search To See Results',
              ),
            ),
          );
        }

        if (value.isSearchingContent && !hasAny) {
          return const Expanded(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!hasAny && value.isSearched && !value.isSearchingContent) {
          return Expanded(
            child: Center(
              child: Text(
                isMalayalam
                    ? 'ഫലങ്ങളൊന്നും കണ്ടെത്തിയില്ല'
                    : 'No results found',
              ),
            ),
          );
        }

        return Expanded(
          child: ListView(
            children: [
              // ── Surahs ──
              if (hasSurahs) ...[
                _buildSectionHeader(
                  context,
                  isMalayalam ? 'സൂറത്ത്' : 'Surahs',
                  '(${value.searchList.length})',
                  isMalayalam,
                ),
                for (int i = 0; i < value.searchList.length; i++) ...[
                  InkWell(
                    onTap: () => _openSurahResult(context, controller, i),
                    child: SettingsScreenCard(
                      child: ListTile(
                        tileColor: Colors.transparent,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${value.searchList[i].surahNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color:
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          isMalayalam &&
                                  value.searchList[i].malayalamName.isNotEmpty
                              ? value.searchList[i].malayalamName
                              : value.searchList[i].name,
                        ),
                        trailing: Text(
                          value.searchList[i].arabicName,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              // ── Loading indicator ──
              if (value.isSearchingContent) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 12),
              ],
              // ── Verse / Translation results ──
              if (hasVerses) ...[
                _buildSectionHeader(
                  context,
                  isMalayalam ? 'ഭാഷാന്തരം' : 'Translations',
                  '(${value.verseSearchResults.length})',
                  isMalayalam,
                ),
                for (final result in value.verseSearchResults) ...[
                  Builder(
                    builder: (ctx) {
                      final surah = value.surahList.firstWhere(
                        (s) => s.surahNumber == result.surahNumber,
                        orElse: () => value.surahList.first,
                      );
                      return VerseSearchResultCard(
                        result: result,
                        surah: surah,
                        isMalayalam: isMalayalam,
                        onTap: () =>
                            _openVerseResult(ctx, controller, result),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              // ── Interpretation / Footnote results ──
              if (hasInterps) ...[
                _buildSectionHeader(
                  context,
                  isMalayalam ? 'വ്യാഖ്യാനം' : 'Interpretations',
                  '(${value.interpretationSearchResults.length})',
                  isMalayalam,
                ),
                for (final result in value.interpretationSearchResults) ...[
                  Builder(
                    builder: (ctx) {
                      final surah = result.surahNumber != -1
                          ? value.surahList.firstWhere(
                              (s) => s.surahNumber == result.surahNumber,
                              orElse: () => value.surahList.first,
                            )
                          : null;
                      return InterpretationSearchResultCard(
                        result: result,
                        surah: surah,
                        isMalayalam: isMalayalam,
                        onTap: result.surahNumber != -1
                            ? () => _openInterpretationResult(
                                ctx, controller, result)
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  // ─── Desktop results ─────────────────────────────────────────────────────

  Widget _buildDesktopResults(BuildContext context, SurahProvider controller) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? Colors.white : Theme.of(context).colorScheme.primary;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[600]!;

    return Consumer<SurahProvider>(
      builder: (context, value, child) {
        final hasSurahs = value.searchList.isNotEmpty;
        final hasVerses = value.verseSearchResults.isNotEmpty;
        final hasInterps = value.interpretationSearchResults.isNotEmpty;
        final hasAny = hasSurahs || hasVerses || hasInterps;

        if (!value.isSearched && !value.isSearchingContent) {
          return Center(
            child: Text(
              isMalayalam
                  ? 'സൂറത്ത്, ഭാഷാന്തരം, ഫുട്ട്നോട്ട് തിരയൂ.'
                  : 'Search surahs, verse translations or interpretations.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        if (value.isSearchingContent && !hasAny) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!hasAny && value.isSearched && !value.isSearchingContent) {
          return Center(
            child: Text(
              isMalayalam
                  ? 'ഫലങ്ങളൊന്നും കണ്ടെത്തിയില്ല.'
                  : 'No results found.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return ListView(
          children: [
            // ── Surahs ──
            if (hasSurahs) ...[
              _buildSectionHeader(
                context,
                isMalayalam ? 'സൂറത്ത്' : 'Surahs',
                '(${value.searchList.length})',
                isMalayalam,
              ),
              for (int i = 0; i < value.searchList.length; i++) ...[
                Builder(builder: (ctx) {
                  final displayText = formatSurahListDisplayText(
                    isMalayalam: isMalayalam,
                    surahName: value.searchList[i].name,
                    surahTranslation: value.searchList[i].description,
                    malayalamName: value.searchList[i].malayalamName,
                    surahNumber: value.searchList[i].surahNumber,
                  );
                  return InkWell(
                    onTap: () => _openSurahResult(ctx, controller, i),
                    borderRadius: BorderRadius.circular(16),
                    child: SettingsScreenCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            // Surah number badge
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${value.searchList[i].surahNumber}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayText.title,
                                    style: AppTextTheme.localizedLabel(
                                      isMalayalam: isMalayalam,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: primaryTextColor,
                                    ),
                                  ),
                                  if (displayText.subtitle.trim().isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      displayText.subtitle,
                                      style: AppTextTheme.localizedBody(
                                        isMalayalam: isMalayalam,
                                        fontSize: 13,
                                        color: secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              value.searchList[i].arabicName,
                              textAlign: TextAlign.right,
                              style: AppTextTheme.localizedLabel(
                                isMalayalam: false,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
            ],
            // ── Loading indicator ──
            if (value.isSearchingContent) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
            ],
            // ── Verse / Translation results ──
            if (hasVerses) ...[
              _buildSectionHeader(
                context,
                isMalayalam ? 'ഭാഷാന്തരം' : 'Translations',
                '(${value.verseSearchResults.length})',
                isMalayalam,
              ),
              for (final result in value.verseSearchResults) ...[
                Builder(
                  builder: (ctx) {
                    final surah = value.surahList.firstWhere(
                      (s) => s.surahNumber == result.surahNumber,
                      orElse: () => value.surahList.first,
                    );
                    return VerseSearchResultCard(
                      result: result,
                      surah: surah,
                      isMalayalam: isMalayalam,
                      onTap: () =>
                          _openVerseResult(ctx, controller, result),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
            // ── Interpretation / Footnote results ──
            if (hasInterps) ...[
              _buildSectionHeader(
                context,
                isMalayalam ? 'വ്യാഖ്യാനം' : 'Interpretations',
                '(${value.interpretationSearchResults.length})',
                isMalayalam,
              ),
              for (final result in value.interpretationSearchResults) ...[
                Builder(
                  builder: (ctx) {
                    final surah = result.surahNumber != -1
                        ? value.surahList.firstWhere(
                            (s) => s.surahNumber == result.surahNumber,
                            orElse: () => value.surahList.first,
                          )
                        : null;
                    return InterpretationSearchResultCard(
                      result: result,
                      surah: surah,
                      isMalayalam: isMalayalam,
                      onTap: result.surahNumber != -1
                          ? () => _openInterpretationResult(
                              ctx, controller, result)
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        );
      },
    );
  }

  // ─── Desktop body ─────────────────────────────────────────────────────────

  Widget _buildDesktopBody(BuildContext context, SurahProvider controller) {
    final hPad = ResponsiveHelper.horizontalPadding(context);
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? Colors.white : Theme.of(context).colorScheme.primary;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.grey[600]!;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/Group-logo.png',
                height: 84,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 18),
              Text(
                isMalayalam ? 'തിരയുക' : 'Search the Qur\'an',
                textAlign: TextAlign.center,
                style: AppTextTheme.localizedTitle(
                  isMalayalam: isMalayalam,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isMalayalam
                    ? 'സൂറത്ത്, ഭാഷാന്തരം, അല്ലെങ്കിൽ ഫുട്ട്നോട്ട് തിരഞ്ഞ് നേരിട്ട് തുറക്കാം.'
                    : 'Search surahs, verse translations or footnote interpretations.',
                textAlign: TextAlign.center,
                style: AppTextTheme.localizedBody(
                  isMalayalam: isMalayalam,
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 20),
              SettingsScreenCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSearchField(context, controller, isMalayalam),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<SurahProvider>(
                builder: (context, value, child) {
                  final totalCount = value.searchList.length +
                      value.verseSearchResults.length +
                      value.interpretationSearchResults.length;
                  return Row(
                    children: [
                      Text(
                        isMalayalam ? 'റിസൾട്ടുകൾ' : 'Results',
                        style: AppTextTheme.localizedLabel(
                          isMalayalam: isMalayalam,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (value.isSearched || value.isSearchingContent)
                        Text(
                          value.isSearchingContent
                              ? (isMalayalam ? 'തിരയുന്നു...' : 'Searching...')
                              : '$totalCount ${isMalayalam ? 'ഫലങ്ങൾ' : 'results'}',
                          style: AppTextTheme.localizedBody(
                            isMalayalam: isMalayalam,
                            fontSize: 13,
                            color: secondaryTextColor,
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SettingsScreenCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildDesktopResults(context, controller),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SurahProvider>(context, listen: false);
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final useDesktopWebLayout = _useDesktopWebLayout(context);

    return BaseScreenLayout(
      appBar: AppBar(
        title: Text(
          'Search',
          style: AppTextTheme.titleRegular.copyWith(
            color: appBarTitleMatchedAccentColor(context),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          alignment: Alignment.center,
          icon: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Colors.white,
          ),
        ),
      ),
      child: useDesktopWebLayout
          ? _buildDesktopBody(context, controller)
          : Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 10.0),
              child: Column(
                children: [
                  _buildSearchField(context, controller, isMalayalam),
                  const SizedBox(height: 10),
                  _buildMobileResults(context, controller),
                ],
              ),
            ),
    );
  }
}
