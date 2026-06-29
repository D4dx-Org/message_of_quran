import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/juz_hizb_model.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/core/utils/surah_place_localizer.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/responsive_content_wrapper.dart';
import 'package:the_message_of_the_quran/core/widgets/scroll_to_top_button.dart';
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
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const double _webHomeMaxWidth = 1140;
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
  int _selectedWebSectionIndex = 0;
  bool _isWebSearchActive = false;

  @override
  void initState() {
    super.initState();
    // Restore the last-active sub-tab (Surah = 0, Juz = 1) from HomeProvider
    // so that returning via SurahScreen's Home button reopens the correct tab.
    final initialTabIndex =
        context.read<HomeProvider>().homeSubTabIndex.clamp(0, 1);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTabIndex,
    );
    _tabController.addListener(_handleTabChange);
    _listController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<JuzHizbProvider>().loadJuz();
    });
  }

  bool _useWebHome(BuildContext context) {
    return kIsWeb;
  }

  void _onScroll() {
    final offset = _listController.hasClients ? _listController.offset : 0.0;
    final shouldShow = offset > 200;
    if (mounted && _useWebHome(context)) {
      if (shouldShow != _showScrollToTop) {
        setState(() => _showScrollToTop = shouldShow);
      }
      return;
    }
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
    final index = surahProvider.surahList.indexWhere(
      (surah) => surah.surahNumber == surahNumber,
    );
    if (index < 0) return;

    surahProvider.assignIndex(index);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SurahScreen(scrollToAyahId: ayahId)),
    );
    if (!context.mounted) return;
    if (saveTabSelection) {
      // Use the surah the provider is currently on, so a jump to a different
      // surah inside the SurahScreen is reflected here instead of the
      // originally opened surah.
      final currentIndex = surahProvider.index;
      if (currentIndex >= 0 &&
          currentIndex < surahProvider.surahList.length) {
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

  void _selectWebSection(int index) {
    if (_selectedWebSectionIndex == index) return;
    setState(() {
      _selectedWebSectionIndex = index;
      _showScrollToTop = _listController.hasClients
          ? _listController.offset > 200
          : false;
    });
  }

  double? _webHomeContentMaxWidth(BuildContext context) {
    if (!kIsWeb) return null;

    final width = MediaQuery.sizeOf(context).width;
    if (width < 1100) return null;

    return (width * 0.84).clamp(920.0, 1080.0).toDouble();
  }

  double? _webHomeTabBarMaxWidth(BuildContext context) {
    final contentWidth = _webHomeContentMaxWidth(context);
    if (contentWidth == null) return null;

    return contentWidth.clamp(680.0, 760.0).toDouble();
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
        ? const Color(0xff163d6e)
        : const Color.fromRGBO(230, 230, 230, 1);
    final selectedBg = isDarkMode
        ? AppTheme.appThemePrimary
        : AppTheme.appThemePrimary;
    final unselectedBg = isDarkMode
        ? const Color(0xff163d6e)
        : const Color.fromRGBO(221, 221, 221, 1);
    const selectedTextColor = Colors.white;
    final unselectedTextColor = isDarkMode
        ? Colors.grey[400]!
        : AppTheme.appThemePrimary;
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final tabs = isMalayalam ? ['സൂറത്ത്', 'ജുസ്അ്'] : ['Surah', "Juz'"];
    final tabBarMaxWidth = _webHomeTabBarMaxWidth(context);

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
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(index),
                      child: Container(
                        height: 26,
                        decoration: BoxDecoration(
                          color: currentIndex == index
                              ? selectedBg
                              : unselectedBg,
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

  Color _webSecondaryText(BuildContext context) {
    return _isDarkWebSurface(context) ? Colors.white70 : Colors.grey[600]!;
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
    final emblemWidth = (width * 0.105).clamp(95.0, 148.0).toDouble();
    final titleWidth = (width * 0.122).clamp(108.0, 202.0).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/symbol-logo.png',
              width: emblemWidth,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            // const SizedBox(height: 8),
            Image.asset(
              'assets/images/symbol-logo-text.png',
              width: titleWidth,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              color: _isDarkWebSurface(context)
                  ? Colors.white.withValues(alpha: 0.85)
                  : AppTheme.appThemePrimary,
              colorBlendMode: BlendMode.srcIn,
            ),
          ],
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
          constraints: const BoxConstraints(maxWidth: 920),
          child: SurahQuickSearch(
            isMalayalam: isMalayalam,
            surahList: surahList,
            isLoading: isLoading,
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
    final secondaryTextColor = _webSecondaryText(context);
    final outlineColor = _webSurfaceBorder(context);
    final fillColor = _isDarkWebSurface(context)
        ? Theme.of(context).scaffoldBackgroundColor
        : Colors.white;
    final isCompactWebHome = _useCompactWebHome(context);
    final sectionLabels = isMalayalam
      ? const ['സൂറത്ത്', 'ജുസ്അ്']
      : const ['Surah', "Juz'"];

    Widget buildTabStrip() {
      return Wrap(
        alignment: WrapAlignment.start,
        spacing: 24,
        runSpacing: 8,
        children: List.generate(sectionLabels.length, (index) {
          final isSelected = _selectedWebSectionIndex == index;
          return InkWell(
            onTap: () => _selectWebSection(index),
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sectionLabels[index],
                    style: TextStyle(
                      color: isSelected ? primaryTextColor : secondaryTextColor,
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    height: 3,
                    width: isSelected ? 48 : 0,
                    decoration: BoxDecoration(
                      color: AppTheme.appThemePrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      );
    }

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

    final isJuzSection = _selectedWebSectionIndex == 1;
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
              Expanded(child: buildTabStrip()),
              const SizedBox(width: 16),
              buildSectionDropdown(
                width: dropdownWidth,
                fieldKey: dropdownFieldKey,
                hintText: dropdownHintText,
                items: dropdownItems,
                onChanged: handleDropdownChanged,
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTabStrip(),
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
    final lastSurahTabSelection =
        context.watch<LastReadProvider>().lastSurahTabSelection;
    final compactGridMaxCrossAxisExtent = isMalayalam ? 420.0 : 400.0;

    switch (_selectedWebSectionIndex) {
      case 1:
        if (juzHizbProvider.isLoading && juzHizbProvider.juzList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
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
              isHighlighted: juzHizbProvider.selectedJuzNumber == juz.number,
              onTap: () => _openJuz(context, juz: juz),
            );
          },
        );
      case 2:
      case 0:
      default:
        if (surahProvider.isSurahLoading) {
          return const Center(child: CircularProgressIndicator());
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
        final itemWidth =
            ((availableWidth - totalSpacing) / columns).clamp(0.0, maxCrossAxisExtent);

        return Wrap(
          spacing: crossAxisSpacing,
          runSpacing: mainAxisSpacing,
          children: List.generate(
            itemCount,
            (index) => SizedBox(
              width: itemWidth,
              child: itemBuilder(context, index),
            ),
          ),
        );
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
                    if (!hasActiveWebSearch) ...[
                      _buildWebPopularSection(
                        context,
                        isMalayalam: isMalayalam,
                        surahList: surahProvider.surahList,
                      ),
                      const SizedBox(height: _webPopularToBrowseGap),
                      DecoratedBox(
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
                    ],
                  ],
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

class _WebPopularSurahCard extends StatelessWidget {
  const _WebPopularSurahCard({
    required this.isMalayalam,
    required this.title,
    required this.onTap,
  });

  final bool isMalayalam;
  final String title;
  final VoidCallback onTap;

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
  });

  final VoidCallback onTap;
  final Color surfaceColor;
  final Color borderColor;
  final Color hoverSurfaceColor;
  final Color hoverBorderColor;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final Widget child;

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

    return Material(
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
    this.isHighlighted = false,
  });

  final bool isMalayalam;
  final int number;
  final String title;
  final String subtitle;
  final String ayahReferenceLabel;
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

    return _WebHoverSurface(
      onTap: onTap,
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
