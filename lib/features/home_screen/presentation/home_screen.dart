import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:the_message_of_the_quran/core/models/juz_hizb_model.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/services/database/database_ready_notifier.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/core/utils/surah_place_localizer.dart';
import 'package:the_message_of_the_quran/core/widgets/app_footer.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/link_hover/hover_link.dart';
import 'package:the_message_of_the_quran/core/widgets/responsive_content_wrapper.dart';
import 'package:the_message_of_the_quran/core/widgets/scroll_to_top_button.dart';
import 'package:the_message_of_the_quran/core/widgets/shimmer_asset_image.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_screen_list.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/juz_column.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/surah_chip_row.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/juz_hizb_provider.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/last_read_provider.dart';
import 'package:the_message_of_the_quran/features/mushaf/widgets/star_number.dart';
import 'package:the_message_of_the_quran/features/search_screen/presentation/widgets/surah_quick_search.dart';
// hide Expanded, AppTextTheme, InputDecoration;
import 'package:the_message_of_the_quran/features/main_screen/providers/home_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const double _webHomeMaxWidth = 1140;
  static const double _webTabBarMaxWidth = 400.0;
  static const double _webPopularCompactSidePadding = 6;
  static const double _webPopularRegularSidePadding = 8;
  static const double _webPopularCompactGap = 8;
  static const double _webPopularRegularGap = 10;
  static const double _webPopularToBrowseGap = 18;
  static const EdgeInsets _webPopularChipPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 6,
  );

  final ScrollController _listController = ScrollController();
  bool _showScrollToTop = false;
  late final TabController _tabController;
  bool _isWebSearchActive = false;

  @override
  void initState() {
    super.initState();
    // Restore the last-active sub-tab (Surah = 0, Juz = 1) from HomeProvider
    // so that returning via SurahScreen's Home button reopens the correct tab.
    final initialTabIndex = context.read<HomeProvider>().homeSubTabIndex.clamp(
      0,
      1,
    );
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTabIndex,
    );
    _tabController.addListener(_handleTabChange);
    _listController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await context.read<DatabaseReadyNotifier>().whenReady;
      } catch (_) {
        return;
      }
      if (!mounted) return;
      context.read<JuzHizbProvider>().loadJuz();
    });
  }

  bool _useWebHome(BuildContext context) {
    return kIsWeb;
  }

  void _onScroll() {
    final offset = _listController.hasClients ? _listController.offset : 0.0;
    if (mounted && _useWebHome(context)) {
      // Near the bottom the footer sits under the button on tablet/mobile
      // web widths (the browse panel spans full width there), so hide the
      // button before it overlaps the footer's "Powered by D4DX" link.
      final maxScrollExtent = _listController.hasClients
          ? _listController.position.maxScrollExtent
          : 0.0;
      final nearBottom = maxScrollExtent - offset < 120;
      final shouldShow = offset > 200 && !nearBottom;
      if (shouldShow != _showScrollToTop) {
        setState(() => _showScrollToTop = shouldShow);
      }
      return;
    }
    final shouldShow = offset > 200;
    if (_tabController.index != 0) {
      if (_showScrollToTop) {
        setState(() => _showScrollToTop = false);
      }
      return;
    }
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    // Persist the new active sub-tab so it can be restored if MainScreen is
    // rebuilt (e.g. when the user presses the Home button in SurahScreen).
    context.read<HomeProvider>().setHomeSubTabIndex(_tabController.index);
    if (_useWebHome(context)) {
      setState(() {});
      return;
    }
    if (_tabController.index != 0) {
      if (_showScrollToTop) {
        setState(() => _showScrollToTop = false);
      }
      return;
    }
    _onScroll();
  }

  void _scrollToTop() {
    if (_listController.hasClients) {
      _listController.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _openSurah(
    BuildContext context, {
    required int surahNumber,
    int? ayahId,
    // When false the Surah-tab highlight (lastSurahTabSelection) is not
    // updated.  Pass false when opening from the Juz tab so that the two
    // tabs remain fully independent.
    bool saveTabSelection = true,
  }) async {
    final surahProvider = context.read<SurahProvider>();
    await context.push(
      '/surah/$surahNumber${ayahId != null ? '?scrollToAyahId=$ayahId' : ''}',
    );
    if (!context.mounted) return;
    if (saveTabSelection) {
      // Use the surah the provider is currently on, so a jump to a different
      // surah inside the SurahScreen is reflected here instead of the
      // originally opened surah.
      final currentIndex = surahProvider.index;
      if (currentIndex >= 0 && currentIndex < surahProvider.surahList.length) {
        context.read<LastReadProvider>().saveLastSurahTabSelection(
          surahProvider.surahList[currentIndex].surahNumber,
        );
      }
    }
  }

  Future<void> _openJuz(
    BuildContext context, {
    required JuzHizbModel juz,
  }) async {
    // saveTabSelection: false keeps the Surah tab's independent highlight
    // untouched when the user navigates from the Juz tab.
    await _openSurah(
      context,
      surahNumber: juz.surahNumber,
      ayahId: juz.ayahNumber,
      saveTabSelection: false,
    );
    if (!context.mounted) return;
    await context.read<JuzHizbProvider>().selectJuz(juz.number);
  }

  double? _webHomeContentMaxWidth(BuildContext context) {
    if (!kIsWeb) return null;

    final width = MediaQuery.sizeOf(context).width;
    if (width < 1100) return null;

    return (width * 0.84).clamp(920.0, 1080.0).toDouble();
  }

  double? _webBrowsePanelMaxWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 1100) return null;

    return (width * 0.8).clamp(960.0, 1400.0).toDouble();
  }

  double? _webHomeTabBarMaxWidth(BuildContext context) {
    if (!kIsWeb) return null;

    return _webTabBarMaxWidth;
  }

  /// 70% of the rendered width of the surah index container (the browse
  /// panel below), so the search bar tracks it at every breakpoint.
  double _webSearchBarMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = _webHorizontalPadding(context);
    final browsePanelMaxWidth =
        _webBrowsePanelMaxWidth(context) ?? double.infinity;
    final containerWidth = math.min(
      screenWidth - 2 * horizontalPadding,
      browsePanelMaxWidth,
    );
    return containerWidth * 0.7;
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Widget _buildTabBar(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDarkMode
        ? AppTheme.darkContentSurfaceBottomColor
        : const Color.fromRGBO(230, 230, 230, 1);
    final selectedBg = isDarkMode
        ? AppTheme.appThemePrimary
        : AppTheme.appThemePrimary;
    final unselectedBg = isDarkMode
        ? AppTheme.darkContentSurfaceBottomColor
        : const Color.fromRGBO(221, 221, 221, 1);
    final hoveredBg = isDarkMode
        ? AppTheme.appThemePrimary.withValues(alpha: 0.6)
        : const Color.fromRGBO(209, 209, 209, 1);
    const selectedTextColor = Colors.white;
    final unselectedTextColor = isDarkMode
        ? Colors.grey[400]!
        : AppTheme.appThemePrimary;
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final tabs = isMalayalam ? ['സൂറത്ത്', 'ജുസ്അ്'] : ['Surah', "Juz'"];
    final tabBarMaxWidth = _webHomeTabBarMaxWidth(context);
    final homeProvider = context.watch<HomeProvider>();
    final hoveredTabIndex = homeProvider.hoveredSubTabIndex;

    final tabBar = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 34,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedBuilder(
          animation: _tabController.animation!,
          builder: (context, _) {
            final currentIndex = _tabController.animation!.value.round();
            return Row(
              children: [
                for (int index = 0; index < tabs.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) => homeProvider.setHoveredSubTabIndex(index),
                      onExit: (_) => homeProvider.setHoveredSubTabIndex(null),
                      child: GestureDetector(
                        onTap: () => _tabController.animateTo(index),
                        child: Container(
                          height: 26,
                          decoration: BoxDecoration(
                            color: currentIndex == index
                                ? selectedBg
                                : (hoveredTabIndex == index
                                      ? hoveredBg
                                      : unselectedBg),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            tabs[index],
                            style: AppTextTheme.localizedLabel(
                              isMalayalam: isMalayalam,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: currentIndex == index
                                  ? selectedTextColor
                                  : unselectedTextColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );

    if (tabBarMaxWidth == null) {
      return tabBar;
    }

    return ResponsiveContentWrapper(maxWidth: tabBarMaxWidth, child: tabBar);
  }

  Widget _buildTabBody() {
    return TabBarView(
      controller: _tabController,
      children: [
        HomeScreenList(scrollController: _listController),
        _buildJuzTab(),
      ],
    );
  }

  Widget _buildJuzTab() => const JuzColumn();

  bool _isDarkWebSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  Color _webPrimaryText(BuildContext context) {
    return _isDarkWebSurface(context) ? Colors.white : AppTheme.appThemePrimary;
  }

  Color _webSurfaceBorder(BuildContext context) {
    final theme = Theme.of(context);
    return _isDarkWebSurface(context)
        ? Colors.white.withValues(alpha: 0.12)
        : (theme.dividerTheme.color ?? theme.colorScheme.outlineVariant);
  }

  double _webHorizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width < 640 ? 12.0 : 24.0;
  }

  bool _useCompactWebHome(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 760;
  }

  String _webFeaturedTitle({
    required bool isMalayalam,
    required SurahModel surah,
    int? ayahId,
  }) {
    if (ayahId == 255) {
      return formatAyatulKursiLabel(isMalayalam: isMalayalam);
    }

    return formatSurahListDisplayText(
      isMalayalam: isMalayalam,
      surahName: surah.name,
      surahTranslation: surah.description,
      malayalamName: surah.malayalamName,
      surahNumber: surah.surahNumber,
    ).title;
  }

  BoxDecoration _webPanelDecoration(
    BuildContext context, {
    double radius = 20,
  }) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: _isDarkWebSurface(context)
          ? null
          : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(255, 255, 255, 1),
                Color.fromRGBO(255, 250, 234, 1),
              ],
            ),
      color: _isDarkWebSurface(context) ? Theme.of(context).cardColor : null,
      border: Border.all(color: _webSurfaceBorder(context)),
    );
  }

  Widget _buildWebBrandingHero(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final emblemWidth = (width * 0.0945).clamp(85.5, 133.2).toDouble();
    final titleWidth = (width * 0.1098).clamp(97.2, 181.8).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Center(
        child: _WebBrandingLogo(
          emblemWidth: emblemWidth,
          titleWidth: titleWidth,
          titleColor: _isDarkWebSurface(context)
              ? Colors.white.withValues(alpha: 0.85)
              : AppTheme.appThemePrimary,
        ),
      ),
    );
  }

  Widget _buildWebHero(
    BuildContext context, {
    required bool isMalayalam,
    required List<SurahModel> surahList,
    required bool isLoading,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 30),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: _webSearchBarMaxWidth(context)),
          child: SurahQuickSearch(
            isMalayalam: isMalayalam,
            surahList: surahList,
            isLoading: isLoading,
            fieldMaxWidth: _webSearchBarMaxWidth(context),
            resultsMaxWidth: _webSearchBarMaxWidth(context),
            onSearchActiveChanged: (isActive) {
              if (_isWebSearchActive == isActive) return;
              setState(() {
                _isWebSearchActive = isActive;
              });
            },
            onSurahSelected: (surahNumber) {
              _openSurah(context, surahNumber: surahNumber);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWebPopularSection(
    BuildContext context, {
    required bool isMalayalam,
    required List<SurahModel> surahList,
  }) {
    final featured = <({SurahModel surah, int? ayahId, String title})>[];
    for (final chip in SurahChipRow.chips) {
      final surah = surahList
          .where((item) => item.surahNumber == chip.surahNumber)
          .firstOrNull;
      if (surah == null) continue;

      featured.add((
        surah: surah,
        ayahId: chip.ayahId,
        title: _webFeaturedTitle(
          isMalayalam: isMalayalam,
          surah: surah,
          ayahId: chip.ayahId,
        ),
      ));
    }

    if (featured.isEmpty) {
      return const SizedBox.shrink();
    }

    final isCompactWebHome = _useCompactWebHome(context);
    final sidePadding = isCompactWebHome
        ? _webPopularCompactSidePadding
        : _webPopularRegularSidePadding;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.all(sidePadding),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < featured.length; index++) ...[
                      if (index > 0)
                        SizedBox(
                          width: isCompactWebHome
                              ? _webPopularCompactGap
                              : _webPopularRegularGap,
                        ),
                      _WebPopularSurahCard(
                        isMalayalam: isMalayalam,
                        title: featured[index].title,
                        url:
                            '/surah/${featured[index].surah.surahNumber}${featured[index].ayahId != null ? '?scrollToAyahId=${featured[index].ayahId}' : ''}',
                        onTap: () => _openSurah(
                          context,
                          surahNumber: featured[index].surah.surahNumber,
                          ayahId: featured[index].ayahId,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebSectionHeader(
    BuildContext context, {
    required bool isMalayalam,
    required List<SurahModel> surahList,
    required List<JuzHizbModel> juzList,
  }) {
    final primaryTextColor = _webPrimaryText(context);
    final outlineColor = _webSurfaceBorder(context);
    final fillColor = _isDarkWebSurface(context)
        ? Theme.of(context).scaffoldBackgroundColor
        : Colors.white;
    final isCompactWebHome = _useCompactWebHome(context);

    Widget buildSectionDropdown({
      required double width,
      required Key fieldKey,
      required String hintText,
      required List<DropdownMenuItem<int>> items,
      required ValueChanged<int?> onChanged,
    }) {
      return SizedBox(
        width: width,
        child: DropdownButtonFormField<int>(
          key: fieldKey,
          initialValue: null,
          isExpanded: true,
          dropdownColor: _isDarkWebSurface(context)
              ? Theme.of(context).cardColor
              : Colors.white,
          iconEnabledColor: primaryTextColor,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.appThemePrimary),
            ),
          ),
          style: TextStyle(color: primaryTextColor, fontSize: 14),
          hint: Text(
            hintText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(color: primaryTextColor),
          ),
          items: items,
          onChanged: onChanged,
        ),
      );
    }

    final isJuzSection = _tabController.index == 1;
    final dropdownFieldKey = isJuzSection
        ? const ValueKey('webJuzSelector')
        : const ValueKey('webSurahSelector');
    final dropdownHintText = isJuzSection
        ? (isMalayalam ? 'ജുസ്അ് തിരയുക' : 'Select juz')
        : (isMalayalam ? 'സൂറത്ത് തിരയുക' : 'Select surah');
    final dropdownItems = isJuzSection
        ? juzList
              .map(
                (juz) => DropdownMenuItem<int>(
                  value: juz.number,
                  child: Text(
                    formatJuzSelectorItemLabel(
                      juz: juz,
                      surahList: surahList,
                      isMalayalam: isMalayalam,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(growable: false)
        : surahList
              .map((surah) {
                final displayText = formatSurahListDisplayText(
                  isMalayalam: isMalayalam,
                  surahName: surah.name,
                  surahTranslation: surah.description,
                  malayalamName: surah.malayalamName,
                  surahNumber: surah.surahNumber,
                );
                return DropdownMenuItem<int>(
                  value: surah.surahNumber,
                  child: Text(
                    '${surah.surahNumber}. ${displayText.title}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              })
              .toList(growable: false);

    void handleDropdownChanged(int? selectedValue) {
      if (selectedValue == null) return;
      if (!isJuzSection) {
        _openSurah(context, surahNumber: selectedValue);
        return;
      }

      final juzIndex = juzList.indexWhere((juz) => juz.number == selectedValue);
      if (juzIndex < 0) return;

      _openJuz(context, juz: juzList[juzIndex]);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const dropdownWidth = 220.0;
        final stackedColumns = constraints.maxWidth < 640 ? 1 : 2;
        final stackedSpacing = 12.0 * (stackedColumns - 1);
        final stackedDropdownWidth = isCompactWebHome
            ? ((constraints.maxWidth - stackedSpacing) / stackedColumns)
                  .clamp(0.0, isMalayalam ? 420.0 : 400.0)
                  .toDouble()
            : dropdownWidth;
        final minInlineWidth = isMalayalam ? 560.0 : 520.0;
        final canFitInlineHeader = constraints.maxWidth >= minInlineWidth;

        if (canFitInlineHeader) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTabBar(context)),
              const SizedBox(width: 16),
              // buildSectionDropdown(
              //   width: dropdownWidth,
              //   fieldKey: dropdownFieldKey,
              //   hintText: dropdownHintText,
              //   items: dropdownItems,
              //   onChanged: handleDropdownChanged,
              // ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabBar(context),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: buildSectionDropdown(
                width: stackedDropdownWidth,
                fieldKey: dropdownFieldKey,
                hintText: dropdownHintText,
                items: dropdownItems,
                onChanged: handleDropdownChanged,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWebSectionBody(
    BuildContext context, {
    required bool isMalayalam,
    required SurahProvider surahProvider,
    required JuzHizbProvider juzHizbProvider,
  }) {
    final surahByNumber = {
      for (final surah in surahProvider.surahList) surah.surahNumber: surah,
    };
    final lastSurahTabSelection = context
        .watch<LastReadProvider>()
        .lastSurahTabSelection;
    final compactGridMaxCrossAxisExtent = isMalayalam ? 420.0 : 400.0;
    // On the first visit the DB copy runs in the background after this tab
    // has already painted, before getAllSurah()/loadJuz() ever set their own
    // isLoading flag — cover that gap so the tab shows a spinner instead of
    // an empty grid, scoped to this tab only (not a full-screen loader).
    final dbNotReady =
        context.watch<DatabaseReadyNotifier>().status != DbInitStatus.ready;

    switch (_tabController.index) {
      case 1:
        if (juzHizbProvider.juzList.isEmpty &&
            (dbNotReady || juzHizbProvider.isLoading)) {
          return _buildWebCardSkeletonGrid(
            maxCrossAxisExtent: compactGridMaxCrossAxisExtent,
          );
        }
        return _buildWebCardGrid(
          itemCount: juzHizbProvider.juzList.length,
          maxCrossAxisExtent: compactGridMaxCrossAxisExtent,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          itemBuilder: (context, index) {
            final juz = juzHizbProvider.juzList[index];
            final surah = surahByNumber[juz.surahNumber];
            final displayText = surah == null
                ? SurahListDisplayText(
                    title: isMalayalam
                        ? 'സൂറത്ത് ${juz.surahNumber}'
                        : 'Surah ${juz.surahNumber}',
                    subtitle: '',
                  )
                : formatSurahListDisplayText(
                    isMalayalam: isMalayalam,
                    surahName: surah.name,
                    surahTranslation: surah.description,
                    malayalamName: surah.malayalamName,
                    surahNumber: surah.surahNumber,
                  );
            final subtitle = displayText.subtitle.trim().isEmpty
                ? (isMalayalam ? 'ജുസ്അ് ${juz.number}' : 'Juz ${juz.number}')
                : displayText.subtitle;
            return _WebCompactJuzCard(
              isMalayalam: isMalayalam,
              number: juz.number,
              title: displayText.title,
              subtitle: subtitle,
              ayahReferenceLabel: formatAyahReferenceLabel(
                juz.ayahNumber,
                isMalayalam: isMalayalam,
              ),
              surahNumber: juz.surahNumber,
              ayahNumber: juz.ayahNumber,
              isHighlighted: juzHizbProvider.selectedJuzNumber == juz.number,
              onTap: () => _openJuz(context, juz: juz),
            );
          },
        );
      case 2:
      case 0:
      default:
        if (surahProvider.surahList.isEmpty &&
            (dbNotReady || surahProvider.isSurahLoading)) {
          return _buildWebCardSkeletonGrid(
            maxCrossAxisExtent: compactGridMaxCrossAxisExtent,
          );
        }
        return _buildWebCardGrid(
          itemCount: surahProvider.surahList.length,
          maxCrossAxisExtent: compactGridMaxCrossAxisExtent,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          itemBuilder: (context, index) {
            final surah = surahProvider.surahList[index];
            final displayText = formatSurahListDisplayText(
              isMalayalam: isMalayalam,
              surahName: surah.name,
              surahTranslation: surah.description,
              malayalamName: surah.malayalamName,
              surahNumber: surah.surahNumber,
            );
            return _WebCompactSurahCard(
              isMalayalam: isMalayalam,
              number: surah.surahNumber,
              title: displayText.title,
              subtitle: displayText.subtitle,
              placeLabel: localizeSurahPlace(
                surah.place,
                isMalayalam: isMalayalam,
                preferBareUncertain: true,
              ),
              ayahCountLabel: formatAyahCountLabel(
                surah.ayathCount,
                isMalayalam: isMalayalam,
              ),
              isHighlighted: lastSurahTabSelection == surah.surahNumber,
              onTap: () => _openSurah(context, surahNumber: surah.surahNumber),
            );
          },
        );
    }
  }

  /// Skeleton placeholder for the Surah/Juz grid, shown in place of the real
  /// cards while data is loading — same grid/card shape so there's no layout
  /// shift once content arrives.
  Widget _buildWebCardSkeletonGrid({required double maxCrossAxisExtent}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDarkMode
        ? Colors.grey.shade700
        : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: _buildWebCardGrid(
        itemCount: 20,
        maxCrossAxisExtent: maxCrossAxisExtent,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        itemBuilder: (context, index) =>
            _WebCompactCardSkeleton(color: baseColor),
      ),
    );
  }

  Widget _buildWebCardGrid({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    double maxCrossAxisExtent = 460,
    double crossAxisSpacing = 16,
    double mainAxisSpacing = 16,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final columns = availableWidth < 640
            ? 1
            : availableWidth < 960
            ? 2
            : 3;
        final totalSpacing = crossAxisSpacing * (columns - 1);
        final itemWidth = ((availableWidth - totalSpacing) / columns).clamp(
          0.0,
          maxCrossAxisExtent,
        );

        final grid = Wrap(
          spacing: crossAxisSpacing,
          runSpacing: mainAxisSpacing,
          alignment: columns == 1
              ? WrapAlignment.center
              : WrapAlignment.start,
          children: List.generate(
            itemCount,
            (index) =>
                SizedBox(width: itemWidth, child: itemBuilder(context, index)),
          ),
        );

        return columns == 1 ? Center(child: grid) : grid;
      },
    );
  }

  Widget _buildWebHome(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final surahProvider = context.watch<SurahProvider>();
    final juzHizbProvider = context.watch<JuzHizbProvider>();
    final horizontalPadding = _webHorizontalPadding(context);
    final hasActiveWebSearch = _isWebSearchActive;

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Stack(
        children: [
          ListView(
            controller: _listController,
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              ResponsiveContentWrapper(
                maxWidth: _webHomeMaxWidth,
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildWebBrandingHero(context),
                    _buildWebHero(
                      context,
                      isMalayalam: isMalayalam,
                      surahList: surahProvider.surahList,
                      isLoading: surahProvider.isSurahLoading,
                    ),
                    if (!hasActiveWebSearch)
                      _buildWebPopularSection(
                        context,
                        isMalayalam: isMalayalam,
                        surahList: surahProvider.surahList,
                      ),
                  ],
                ),
              ),
              if (!hasActiveWebSearch) ...[
                const SizedBox(height: _webPopularToBrowseGap),
                ResponsiveContentWrapper(
                  maxWidth: _webBrowsePanelMaxWidth(context),
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: DecoratedBox(
                    decoration: _webPanelDecoration(context),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWebSectionHeader(
                            context,
                            isMalayalam: isMalayalam,
                            surahList: surahProvider.surahList,
                            juzList: juzHizbProvider.juzList,
                          ),
                          const SizedBox(height: 8),
                          _buildWebSectionBody(
                            context,
                            isMalayalam: isMalayalam,
                            surahProvider: surahProvider,
                            juzHizbProvider: juzHizbProvider,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: _webPopularToBrowseGap),
              ResponsiveContentWrapper(
                maxWidth: _webBrowsePanelMaxWidth(context),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: AppFooter(
                  fullBleed: false,
                  maxWidth: _webBrowsePanelMaxWidth(context),
                ),
              ),
            ],
          ),
          PositionedDirectional(
            end: 24,
            bottom: 24,
            child: ScrollToTopButton(
              visible: _showScrollToTop,
              onPressed: _scrollToTop,
              heroTag: 'webHomeScrollToTop',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_useWebHome(context)) {
      return _buildWebHome(context);
    }

    final homeContentMaxWidth = _webHomeContentMaxWidth(context);
    final homeContent = Column(
      children: [
        const SizedBox.shrink(),
        _buildTabBar(context),
        const SizedBox(height: 12),
        Expanded(child: _buildTabBody()),
      ],
    );

    return BaseScreenLayout(
      contentCardBoxShadows: const [],
      topBorderRadius: 70,
      floatingActionButton: ScrollToTopButton(
        visible: _showScrollToTop && _tabController.index == 0,
        onPressed: _scrollToTop,
      ),
      headerContent: Container(
        width: double.infinity,
        color: AppTheme.appThemePrimary,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          child: homeContentMaxWidth == null
              ? const SurahChipRow()
              : ResponsiveContentWrapper(
                  maxWidth: homeContentMaxWidth,
                  child: const SurahChipRow(),
                ),
        ),
      ),
      child: homeContentMaxWidth == null
          ? homeContent
          : ResponsiveContentWrapper(
              maxWidth: homeContentMaxWidth,
              child: homeContent,
            ),
    );
  }
}

/// Emblem + wordmark lockup shown above the web surah search box. Shows one
/// square shimmer placeholder covering both images while they load, then
/// cross-fades to the real logo — a single clean square reads better here
/// than each image's own narrow/tall shimmer shape.
class _WebBrandingLogo extends StatefulWidget {
  const _WebBrandingLogo({
    required this.emblemWidth,
    required this.titleWidth,
    required this.titleColor,
  });

  final double emblemWidth;
  final double titleWidth;
  final Color titleColor;

  @override
  State<_WebBrandingLogo> createState() => _WebBrandingLogoState();
}

class _WebBrandingLogoState extends State<_WebBrandingLogo> {
  bool _ready = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ready) return;
    Future.wait([
      precacheImage(const AssetImage('assets/images/symbol-logo.png'), context),
      precacheImage(
        const AssetImage('assets/images/symbol-logo-text.png'),
        context,
      ),
    ]).then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final emblemHeight = widget.emblemWidth * (276 / 165);
    final titleHeight = widget.titleWidth * (154 / 258);
    final totalHeight = emblemHeight + titleHeight;
    final totalWidth = math.max(widget.emblemWidth, widget.titleWidth);
    final squareSize = emblemHeight;

    final logo = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/symbol-logo.png',
          width: widget.emblemWidth,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        Image.asset(
          'assets/images/symbol-logo-text.png',
          width: widget.titleWidth,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          color: widget.titleColor,
          colorBlendMode: BlendMode.srcIn,
        ),
      ],
    );

    return SizedBox(
      width: totalWidth,
      height: totalHeight,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _ready
              ? KeyedSubtree(key: const ValueKey('logo'), child: logo)
              : ShimmerBox(
                  key: const ValueKey('shimmer'),
                  width: squareSize,
                  height: squareSize,
                  borderRadius: BorderRadius.circular(12),
                ),
        ),
      ),
    );
  }
}

class _WebPopularSurahCard extends StatelessWidget {
  const _WebPopularSurahCard({
    required this.isMalayalam,
    required this.title,
    required this.onTap,
    this.url,
  });

  final bool isMalayalam;
  final String title;
  final VoidCallback onTap;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final surfaceColor = isDarkMode ? theme.cardColor : Colors.white;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.10)
        : (theme.dividerTheme.color ?? theme.colorScheme.outlineVariant);
    final hoverSurfaceColor = isDarkMode
        ? AppTheme.appThemePrimary.withValues(alpha: 0.16)
        : AppTheme.appThemePrimary.withValues(alpha: 0.05);
    final hoverBorderColor = AppTheme.appThemePrimary.withValues(
      alpha: isDarkMode ? 0.42 : 0.24,
    );
    final titleColor = isDarkMode ? Colors.white : AppTheme.appThemePrimary;

    return _WebHoverSurface(
      onTap: onTap,
      url: url,
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      hoverSurfaceColor: hoverSurfaceColor,
      hoverBorderColor: hoverBorderColor,
      borderRadius: BorderRadius.circular(999),
      padding: _HomeScreenState._webPopularChipPadding,
      child: Center(
        child: Text(
          title,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextTheme.localizedLabel(
            isMalayalam: isMalayalam,
            fontSize: isMalayalam ? 13 : 14,
            fontWeight: FontWeight.w700,
            color: titleColor,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _WebHoverSurface extends StatefulWidget {
  const _WebHoverSurface({
    required this.onTap,
    required this.surfaceColor,
    required this.borderColor,
    required this.hoverSurfaceColor,
    required this.hoverBorderColor,
    required this.borderRadius,
    required this.padding,
    required this.child,
    this.url,
  });

  final VoidCallback onTap;
  final Color surfaceColor;
  final Color borderColor;
  final Color hoverSurfaceColor;
  final Color hoverBorderColor;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget child;
  final String? url;

  @override
  State<_WebHoverSurface> createState() => _WebHoverSurfaceState();
}

class _WebHoverSurfaceState extends State<_WebHoverSurface> {
  bool _isHovered = false;

  void _handleHover(bool hovered) {
    if (_isHovered == hovered) return;
    setState(() => _isHovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    final showHover = kIsWeb && _isHovered;
    final hoverShadowColor = AppTheme.appThemePrimary.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.10,
    );

    final surface = Material(
      color: Colors.transparent,
      borderRadius: widget.borderRadius,
      child: InkWell(
        onTap: widget.onTap,
        onHover: _handleHover,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: widget.borderRadius,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: AppTheme.appThemePrimary.withValues(alpha: 0.08),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, showHover ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: showHover ? widget.hoverSurfaceColor : widget.surfaceColor,
            borderRadius: widget.borderRadius,
            border: Border.all(
              color: showHover ? widget.hoverBorderColor : widget.borderColor,
            ),
            boxShadow: showHover
                ? [
                    BoxShadow(
                      color: hoverShadowColor,
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          padding: widget.padding,
          child: widget.child,
        ),
      ),
    );

    return widget.url != null
        ? HoverLink(url: widget.url!, child: surface)
        : surface;
  }
}

/// Static placeholder matching [_WebCompactSurahCard]/[_WebCompactJuzCard]'s
/// row shape (leading circle, two-line title block, trailing box). Meant to
/// sit inside a single [Shimmer.fromColors] ancestor, so it paints in plain
/// [color] rather than shimmering itself.
class _WebCompactCardSkeleton extends StatelessWidget {
  const _WebCompactCardSkeleton({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).scaffoldBackgroundColor
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.10)
              : (Theme.of(context).dividerTheme.color ??
                    Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              child: const SizedBox(width: 40, height: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const SizedBox(width: double.infinity, height: 14),
                  ),
                  const SizedBox(height: 6),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const SizedBox(width: 80, height: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const SizedBox(width: 46, height: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebCompactSurahCard extends StatelessWidget {
  const _WebCompactSurahCard({
    required this.isMalayalam,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.placeLabel,
    required this.ayahCountLabel,
    required this.onTap,
    this.isHighlighted = false,
  });

  final bool isMalayalam;
  final int number;
  final String title;
  final String subtitle;
  final String placeLabel;
  final String ayahCountLabel;
  final VoidCallback onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final surfaceColor = isDarkMode
        ? theme.scaffoldBackgroundColor
        : Colors.white;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.10)
        : (theme.dividerTheme.color ?? theme.colorScheme.outlineVariant);
    final hoverSurfaceColor = isDarkMode
        ? AppTheme.appThemePrimary.withValues(alpha: 0.16)
        : AppTheme.appThemePrimary.withValues(alpha: 0.05);
    final hoverBorderColor = AppTheme.appThemePrimary.withValues(
      alpha: isDarkMode ? 0.42 : 0.24,
    );
    final primaryTextColor = isDarkMode
        ? Colors.white
        : AppTheme.appThemePrimary;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.grey[600]!;
    final trailingColumnWidth = isMalayalam ? 112.0 : 90.0;

    return _WebHoverSurface(
      onTap: onTap,
      url: '/surah/$number',
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      hoverSurfaceColor: hoverSurfaceColor,
      hoverBorderColor: hoverBorderColor,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarNumber(number: number, size: 40, isHighlighted: isHighlighted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      style: AppTextTheme.localizedLabel(
                        isMalayalam: isMalayalam,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  SizedBox(
                    width: double.infinity,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        softWrap: false,
                        style: AppTextTheme.localizedBody(
                          isMalayalam: isMalayalam,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: trailingColumnWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      placeLabel,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.right,
                      style: AppTextTheme.localizedLabel(
                        isMalayalam: isMalayalam,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  ayahCountLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: AppTextTheme.localizedLabel(
                    isMalayalam: isMalayalam,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebCompactJuzCard extends StatelessWidget {
  const _WebCompactJuzCard({
    required this.isMalayalam,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.ayahReferenceLabel,
    required this.onTap,
    required this.surahNumber,
    required this.ayahNumber,
    this.isHighlighted = false,
  });

  final bool isMalayalam;
  final int number;
  final String title;
  final String subtitle;
  final String ayahReferenceLabel;
  final VoidCallback onTap;
  final int surahNumber;
  final int ayahNumber;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final surfaceColor = isDarkMode
        ? theme.scaffoldBackgroundColor
        : Colors.white;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.10)
        : (theme.dividerTheme.color ?? theme.colorScheme.outlineVariant);
    final hoverSurfaceColor = isDarkMode
        ? AppTheme.appThemePrimary.withValues(alpha: 0.16)
        : AppTheme.appThemePrimary.withValues(alpha: 0.05);
    final hoverBorderColor = AppTheme.appThemePrimary.withValues(
      alpha: isDarkMode ? 0.42 : 0.24,
    );
    final primaryTextColor = isDarkMode
        ? Colors.white
        : AppTheme.appThemePrimary;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.grey[600]!;

    return _WebHoverSurface(
      onTap: onTap,
      url: '/surah/$surahNumber?scrollToAyahId=$ayahNumber',
      surfaceColor: surfaceColor,
      borderColor: borderColor,
      hoverSurfaceColor: hoverSurfaceColor,
      hoverBorderColor: hoverBorderColor,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StarNumber(number: number, size: 40, isHighlighted: isHighlighted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      maxLines: 1,
                      softWrap: false,
                      style: AppTextTheme.localizedLabel(
                        isMalayalam: isMalayalam,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      softWrap: false,
                      style: AppTextTheme.localizedBody(
                        isMalayalam: isMalayalam,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            ayahReferenceLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: AppTextTheme.localizedBody(
              isMalayalam: isMalayalam,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
