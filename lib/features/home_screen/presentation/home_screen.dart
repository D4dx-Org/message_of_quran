import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/scroll_to_top_button.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_screen_list.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/juz_column.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/surah_chip_row.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/juz_hizb_provider.dart';
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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _listController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<JuzHizbProvider>().loadJuz();
    });
  }

  void _onScroll() {
    final offset =
        _listController.hasClients ? _listController.offset : 0.0;
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
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final tabs = isMalayalam ? ['സൂറത്ത്', 'ജുസ്'] : ['Surah', "Juz'e"];

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
                          style: GoogleFonts.poppins(
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
  }

  Widget _buildTabBody() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return TabBarView(
      controller: _tabController,
      children: [
        HomeScreenList(scrollController: _listController),
        _buildJuzTab(),
      ],
    );
  }

  Widget _buildJuzTab() => const JuzColumn();

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      topBorderRadius: 70,
      floatingActionButton: ScrollToTopButton(
        visible: _showScrollToTop && _tabController.index == 0,
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
          _buildTabBar(context),
          const SizedBox(height: 12),
          Expanded(child: _buildTabBody()),
        ],
      ),
    );
  }
}

