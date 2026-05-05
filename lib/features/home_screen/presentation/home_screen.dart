import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/juz_hizb_model.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/scroll_to_top_button.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_screen_list.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/surah_chip_row.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/juz_hizb_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _listController = ScrollController();
  bool _showScrollToTop = false;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _listController.addListener(_onScroll);
    // Load juz/hizb data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JuzHizbProvider>().loadAll();
    });
  }

  void _onScroll() {
    final offset =
        _listController.hasClients ? _listController.offset : 0.0;
    final shouldShow = offset > 200;
    if (shouldShow != _showScrollToTop) {
      setState(() => _showScrollToTop = shouldShow);
    }
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

  @override
  void dispose() {
    _tabController.dispose();
    _listController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return BaseScreenLayout(
      topBorderRadius: 70,
      floatingActionButton: ScrollToTopButton(
        visible: _showScrollToTop,
        onPressed: _scrollToTop,
      ),
      headerContent: Container(
        width: double.infinity,
        color: AppTheme.appThemePrimary,
        child: const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 16),
          child: SurahChipRow(),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildPillTabBar(context, isDarkMode),
          const SizedBox(height: 12),
          Expanded(
            child: _buildTabBarView(context, isDarkMode, false),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTabBar(BuildContext context, bool isDarkMode) {
    final containerBg = isDarkMode
        ? const Color(0xFF2C2C2E)
        : const Color.fromRGBO(230, 230, 230, 1);
    final selectedBg = isDarkMode
        ? const Color(0xFF3C3C3C)
        : const Color.fromRGBO(124, 58, 40, 1);
    final unselectedBg = isDarkMode
        ? const Color(0xFF3A3A3C)
        : const Color.fromRGBO(221, 221, 221, 1);
    const selectedTextColor = Colors.white;
    final unselectedTextColor = isDarkMode
        ? Colors.grey[400]!
        : const Color.fromRGBO(124, 58, 40, 1);

    final isMl = context.watch<LanguageProvider>().isMalayalam;
    final tabs = isMl ? ['സൂറത്ത്', 'ജുസ്', 'ഹിസ്ബ്'] : ['Surah', "Juz'e", 'Hizb'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 34,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return Row(
              children: [
                for (int index = 0; index < 3; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _tabController.animateTo(index),
                      child: Container(
                        height: 26,
                        decoration: BoxDecoration(
                          color: _tabController.index == index
                              ? selectedBg
                              : unselectedBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tabs[index],
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _tabController.index == index
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
  }

  Widget _buildTabBarView(BuildContext context, bool isDarkMode, bool isLandscape) {
    return TabBarView(
      controller: _tabController,
      children: [
        HomeScreenList(scrollController: _listController),
        _buildJuzTab(context, isDarkMode),
        _buildHizbTab(context, isDarkMode),
      ],
    );
  }

  // ─── Juz Tab ────────────────────────────────────────────────────────────

  Widget _buildJuzTab(BuildContext context, bool isDarkMode) {
    final hPad = ResponsiveHelper.horizontalPadding(context);
    return Consumer2<JuzHizbProvider, SurahProvider>(
      builder: (context, juzProvider, surahProvider, _) {
        if (juzProvider.isLoading || juzProvider.juzList.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.appIconTheme),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 16),
          itemCount: juzProvider.juzList.length,
          itemBuilder: (context, i) {
            final juz = juzProvider.juzList[i];
            final available = surahProvider.surahList
                .any((s) => s.surahNumber == juz.surahNumber);
            return _buildJuzCard(context, juz, available, isDarkMode);
          },
        );
      },
    );
  }

  Widget _buildJuzCard(
    BuildContext context,
    JuzHizbModel juz,
    bool available,
    bool isDarkMode,
  ) {
    final isMl = context.watch<LanguageProvider>().isMalayalam;
    final textColor = isDarkMode ? Colors.white : const Color.fromRGBO(124, 58, 40, 1);
    final subColor = isDarkMode ? Colors.white54 : Colors.grey[600]!;

    return InkWell(
      onTap: available
          ? () async {
              final surahProv = context.read<SurahProvider>();
              await surahProv.selectSurahByNumber(juz.surahNumber);
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SurahScreen(scrollToAyahId: juz.ayahNumber),
                  ),
                );
              }
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            _buildDiamondBadge(juz.number, isDarkMode),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMl ? 'ജുസ് ${juz.number}' : 'Juz ${juz.number}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMl
                        ? 'സൂറത്ത് ${juz.surahNumber}  •  ആയത്ത് ${juz.ayahNumber}'
                        : 'SURAH ${juz.surahNumber}  •  AYAH ${juz.ayahNumber}',
                    style: TextStyle(
                      color: subColor,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hizb Tab ───────────────────────────────────────────────────────────

  Widget _buildHizbTab(BuildContext context, bool isDarkMode) {
    final hPad = ResponsiveHelper.horizontalPadding(context);
    return Consumer2<JuzHizbProvider, SurahProvider>(
      builder: (context, hizbProvider, surahProvider, _) {
        if (hizbProvider.isLoading || hizbProvider.hizbList.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.appIconTheme),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 16),
          itemCount: hizbProvider.hizbList.length,
          itemBuilder: (context, i) {
            final hizb = hizbProvider.hizbList[i];
            final available = surahProvider.surahList
                .any((s) => s.surahNumber == hizb.surahNumber);
            return _buildHizbCard(context, hizb, available, isDarkMode);
          },
        );
      },
    );
  }

  Widget _buildHizbCard(
    BuildContext context,
    JuzHizbModel hizb,
    bool available,
    bool isDarkMode,
  ) {
    final isMl = context.watch<LanguageProvider>().isMalayalam;
    final textColor = isDarkMode ? Colors.white : const Color.fromRGBO(124, 58, 40, 1);
    final subColor = isDarkMode ? Colors.white54 : Colors.grey[600]!;

    return InkWell(
      onTap: available
          ? () async {
              final surahProv = context.read<SurahProvider>();
              await surahProv.selectSurahByNumber(hizb.surahNumber);
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        SurahScreen(scrollToAyahId: hizb.ayahNumber),
                  ),
                );
              }
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            _buildDiamondBadge(hizb.number, isDarkMode),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMl ? 'ഹിസ്ബ് ${hizb.number}' : 'Hizb ${hizb.number}',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMl
                        ? 'സൂറത്ത് ${hizb.surahNumber}  •  ആയത്ത് ${hizb.ayahNumber}'
                        : 'SURAH ${hizb.surahNumber}  •  AYAH ${hizb.ayahNumber}',
                    style: TextStyle(
                      color: subColor,
                      fontSize: 11,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Diamond Badge ──────────────────────────────────────────────────────

  Widget _buildDiamondBadge(int number, bool isDarkMode) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.785,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? AppTheme.appIconTheme.withValues(alpha: 0.15)
                    : AppTheme.appIconTheme.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.appIconTheme.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
            ),
          ),
          Text(
            '$number',
            style: TextStyle(
              color: AppTheme.appIconTheme,
              fontWeight: FontWeight.w700,
              fontSize: number > 99 ? 10 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

