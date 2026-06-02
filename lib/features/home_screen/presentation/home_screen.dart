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
import 'package:the_message_of_the_quran/features/main_screen/providers/home_provider.dart';
import 'package:the_message_of_the_quran/features/mushaf/widgets/star_number.dart';
import 'package:the_message_of_the_quran/features/prostration_verses/data/prostration_verse_model.dart';
import 'package:the_message_of_the_quran/features/prostration_verses/services/prostration_verses_service.dart';
import 'package:the_message_of_the_quran/features/search_screen/presentation/search_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

const List<int> _webRevelationOrder = [
  96,
  68,
  73,
  74,
  1,
  111,
  81,
  87,
  92,
  89,
  93,
  94,
  103,
  100,
  108,
  102,
  107,
  109,
  105,
  113,
  114,
  112,
  53,
  80,
  97,
  91,
  85,
  95,
  106,
  101,
  75,
  104,
  77,
  50,
  90,
  86,
  54,
  38,
  7,
  72,
  36,
  25,
  35,
  19,
  20,
  56,
  26,
  27,
  28,
  17,
  10,
  11,
  12,
  15,
  6,
  37,
  31,
  34,
  39,
  40,
  41,
  42,
  43,
  44,
  45,
  46,
  51,
  88,
  18,
  16,
  71,
  14,
  21,
  23,
  32,
  52,
  67,
  69,
  70,
  78,
  79,
  82,
  84,
  30,
  29,
  83,
  2,
  8,
  3,
  33,
  60,
  4,
  99,
  57,
  47,
  13,
  55,
  76,
  65,
  98,
  59,
  24,
  22,
  63,
  58,
  49,
  66,
  64,
  61,
  62,
  48,
  5,
  9,
  110,
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const double _webHomeMaxWidth = 1140;

  final ScrollController _listController = ScrollController();
  bool _showScrollToTop = false;
  late final TabController _tabController;
  late final Future<List<ProstrationVerseModel>> _prostrationVersesFuture;
  int _selectedWebSectionIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _prostrationVersesFuture = kIsWeb
      ? ProstrationVersesService.loadVerses()
      : Future.value(const <ProstrationVerseModel>[]);
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
  }) async {
    final surahProvider = context.read<SurahProvider>();
    final index = surahProvider.surahList.indexWhere(
      (surah) => surah.surahNumber == surahNumber,
    );
    if (index < 0) return;

    surahProvider.assignIndex(index);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahScreen(scrollToAyahId: ayahId),
      ),
    );
    if (!mounted) return;
    context.read<LastReadProvider>().saveLastSurahTabSelection(surahNumber);
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
    final tabs = isMalayalam ? ['സൂറത്ത്', 'ജുസ്'] : ['Surah', "Juz'e"];
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

  Color _webHeaderForeground(BuildContext context) {
    return AppTheme.appBarForegroundColor;
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

  BoxDecoration _webPanelDecoration(BuildContext context, {double radius = 20}) {
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

  Widget _buildWebHero(bool isMalayalam) {
    final hintFontSize = isMalayalam ? 14.0 : 15.0;

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 30),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            children: [
              Text(
                isMalayalam
                    ? 'സൂറത്തുകൾ എളുപ്പത്തിൽ തിരയുക, വായിക്കുക, വീണ്ടും തുടർക്കുക.'
                    : 'Search, read, and continue your Qur\'an journey from one place.',
                textAlign: TextAlign.center,
                style: AppTextTheme.localizedBody(
                  isMalayalam: isMalayalam,
                  fontSize: 16,
                  color: _webSecondaryText(context),
                ),
              ),
              const SizedBox(height: 26),
              SearchBar(
                hintText: isMalayalam
                    ? 'സൂറത്ത് തിരയുക'
                    : 'Search surahs, verses, or references...',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
                readOnly: true,
                elevation: const WidgetStatePropertyAll(0),
                side: WidgetStatePropertyAll(
                  BorderSide(color: _webSurfaceBorder(context)),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                shape: const WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(28)),
                  ),
                ),
                textStyle: WidgetStatePropertyAll(
                  AppTextTheme.localizedBody(
                    isMalayalam: isMalayalam,
                    fontSize: 15,
                    color: _webPrimaryText(context),
                  ),
                ),
                hintStyle: WidgetStatePropertyAll(
                  AppTextTheme.localizedBody(
                    isMalayalam: isMalayalam,
                    fontSize: hintFontSize,
                    color: _webSecondaryText(context),
                  ),
                ),
                backgroundColor: WidgetStatePropertyAll(
                  _isDarkWebSurface(context)
                      ? Theme.of(context).cardColor
                      : Colors.white,
                ),
                trailing: [
                  Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      color: _webPrimaryText(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildWebReadModeToggle(context, isMalayalam),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebReadModeToggle(BuildContext context, bool isMalayalam) {
    final selectedIndex = context.watch<HomeProvider>().currentIndex;
    final headerAccent = AppTheme.appThemePrimary;

    return Align(
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: headerAccent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: headerAccent.withValues(alpha: 0.18)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _WebModeButton(
                label: isMalayalam ? 'ഖുർആൻ വായനം' : 'Read Al-Qur\'an',
                selected: selectedIndex == 0,
                onTap: () => context.read<HomeProvider>().changeIndex(0),
              ),
              const SizedBox(width: 4),
              _WebModeButton(
                label: isMalayalam ? 'മുഷ്ഹഫ്' : 'Read Mushaf',
                selected: selectedIndex == 2,
                onTap: () => context.read<HomeProvider>().changeIndex(2),
              ),
            ],
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

      featured.add(
        (
          surah: surah,
          ayahId: chip.ayahId,
          title: _webFeaturedTitle(
            isMalayalam: isMalayalam,
            surah: surah,
            ayahId: chip.ayahId,
          ),
        ),
      );
    }

    if (featured.isEmpty) {
      return const SizedBox.shrink();
    }

    final isCompactWebHome = _useCompactWebHome(context);
    final cardHeight = isCompactWebHome ? 56.0 : 60.0;

    return SizedBox(
      height: cardHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompactWebHome ? 8 : 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0; index < featured.length; index++) ...[
                        if (index > 0)
                          SizedBox(width: isCompactWebHome ? 10 : 12),
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
      ),
    );
  }

  Widget _buildWebSectionHeader(
    BuildContext context, {
    required bool isMalayalam,
    required List<SurahModel> surahList,
  }) {
    final primaryTextColor = _webPrimaryText(context);
    final secondaryTextColor = _webSecondaryText(context);
    final outlineColor = _webSurfaceBorder(context);
    final fillColor = _isDarkWebSurface(context)
        ? Theme.of(context).scaffoldBackgroundColor
        : Colors.white;
    final isCompactWebHome = _useCompactWebHome(context);
    final sectionLabels = isMalayalam
        ? const ['സൂറത്ത്', 'ജുസ്']
        : const ['Surah', 'Juz'];

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
                      color: isSelected
                          ? primaryTextColor
                          : secondaryTextColor,
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

    Widget buildSurahDropdown(double width) {
      return SizedBox(
        width: width,
        child: DropdownButtonFormField<int>(
          value: null,
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
            isMalayalam ? 'സൂറത്ത് തിരഞ്ഞെടുക്കുക' : 'Select surah',
            style: TextStyle(color: primaryTextColor),
          ),
          items: surahList.map((surah) {
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
          }).toList(growable: false),
          onChanged: (surahNumber) {
            if (surahNumber == null) return;
            _openSurah(context, surahNumber: surahNumber);
          },
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const dropdownWidth = 220.0;
        final stackedDropdownWidth = isCompactWebHome
            ? constraints.maxWidth
            : dropdownWidth;
        final minInlineWidth = isMalayalam ? 560.0 : 520.0;
        final canFitInlineHeader = constraints.maxWidth >= minInlineWidth;

        if (canFitInlineHeader) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: buildTabStrip()),
              const SizedBox(width: 16),
              buildSurahDropdown(dropdownWidth),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildTabStrip(),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: buildSurahDropdown(stackedDropdownWidth),
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
    final compactGridMaxCrossAxisExtent = isMalayalam ? 308.0 : 288.0;

    switch (_selectedWebSectionIndex) {
      case 1:
        if (juzHizbProvider.isLoading && juzHizbProvider.juzList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildWebCardGrid(
          itemCount: juzHizbProvider.juzList.length,
          maxCrossAxisExtent: compactGridMaxCrossAxisExtent,
          mainAxisExtent: 90,
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
                ? (isMalayalam ? 'ജുസ് ${juz.number}' : 'Juz ${juz.number}')
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
              onTap: () async {
                await _openSurah(
                  context,
                  surahNumber: juz.surahNumber,
                  ayahId: juz.ayahNumber,
                );
                if (!mounted) return;
                context.read<JuzHizbProvider>().selectJuz(juz.number);
              },
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
          mainAxisExtent: 90,
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
              placeLabel: localizeSurahPlace(
                surah.place,
                isMalayalam: isMalayalam,
                preferBareUncertain: true,
              ),
              ayahCountLabel: formatAyahCountLabel(
                surah.ayathCount,
                isMalayalam: isMalayalam,
              ),
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
    double mainAxisExtent = 132,
    double crossAxisSpacing = 16,
    double mainAxisSpacing = 16,
  }) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        mainAxisExtent: mainAxisExtent,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
      ),
      itemBuilder: itemBuilder,
    );
  }

  Widget _buildWebHome(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final surahProvider = context.watch<SurahProvider>();
    final juzHizbProvider = context.watch<JuzHizbProvider>();
    final horizontalPadding = _webHorizontalPadding(context);

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
                    _buildWebHero(isMalayalam),
                    _buildWebPopularSection(
                      context,
                      isMalayalam: isMalayalam,
                      surahList: surahProvider.surahList,
                    ),
                    const SizedBox(height: 30),
                    DecoratedBox(
                      decoration: _webPanelDecoration(context),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isMalayalam ? 'ഖുർആൻ ബ്രൗസ് ചെയ്യുക' : 'Browse the Qur\'an',
                              style: AppTextTheme.localizedTitle(
                                isMalayalam: isMalayalam,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: _webPrimaryText(context),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isMalayalam
                                  ? 'സൂറത്തുകളും ജുസുകളും വെബ്ബിൽ നിന്ന് വേഗത്തിൽ തുറക്കാം.'
                                  : 'Open surahs and juz quickly in a web-first responsive layout.',
                              style: AppTextTheme.localizedBody(
                                isMalayalam: isMalayalam,
                                fontSize: 14,
                                color: _webSecondaryText(context),
                              ),
                            ),
                            const SizedBox(height: 14),
                            _buildWebSectionHeader(
                              context,
                              isMalayalam: isMalayalam,
                              surahList: surahProvider.surahList,
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
        const SizedBox(height: 20),
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

class _WebModeButton extends StatelessWidget {
  const _WebModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDarkMode
        ? Colors.white70
        : AppTheme.appThemePrimary.withValues(alpha: 0.92);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.appThemeSecondary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected
                ? AppTheme.appThemePrimary
                : unselectedColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
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
    final titleColor = isDarkMode ? Colors.white : AppTheme.appThemePrimary;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
      ),
    );
  }
}

class _WebCompactSurahCard extends StatelessWidget {
  const _WebCompactSurahCard({
    required this.isMalayalam,
    required this.number,
    required this.title,
    required this.placeLabel,
    required this.ayahCountLabel,
    required this.onTap,
  });

  final bool isMalayalam;
  final int number;
  final String title;
  final String placeLabel;
  final String ayahCountLabel;
  final VoidCallback onTap;

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
    final primaryTextColor = isDarkMode ? Colors.white : AppTheme.appThemePrimary;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.grey[600]!;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              StarNumber(number: number, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextTheme.localizedLabel(
                        isMalayalam: isMalayalam,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      placeLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextTheme.localizedBody(
                        isMalayalam: isMalayalam,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                ayahCountLabel,
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
        ),
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
  });

  final bool isMalayalam;
  final int number;
  final String title;
  final String subtitle;
  final String ayahReferenceLabel;
  final VoidCallback onTap;

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
    final primaryTextColor = isDarkMode ? Colors.white : AppTheme.appThemePrimary;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.grey[600]!;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              StarNumber(number: number, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextTheme.localizedLabel(
                        isMalayalam: isMalayalam,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextTheme.localizedBody(
                        isMalayalam: isMalayalam,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
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
        ),
      ),
    );
  }
}
