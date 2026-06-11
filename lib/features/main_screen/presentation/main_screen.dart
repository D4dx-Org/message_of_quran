import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/app_bar_language_button.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/core/widgets/responsive_content_wrapper.dart';
import 'package:the_message_of_the_quran/features/about_screen/presentation/about_screen.dart';
import 'package:the_message_of_the_quran/features/bookmark_screen/presentation/bookmark_screen.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/home_screen.dart';
import 'package:the_message_of_the_quran/features/main_screen/providers/home_provider.dart';
import 'package:the_message_of_the_quran/features/mushaf/screens/mushaf_landing_screen.dart';
import 'package:the_message_of_the_quran/features/search_screen/presentation/widgets/surah_quick_search.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/settings_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';
import 'package:the_message_of_the_quran/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  static void navigateToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainScreenState>();
    state?._onItemTapped(index);
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final Set<int> _hoveredWebNavItems = <int>{};
  static const double _navIconSize = 24;
  static const double _webShellMaxWidth = 1180;
  static const List<({String label, int pageIndex})> _webNavItems = [
    (label: 'Home', pageIndex: 0),
    (label: 'Bookmarks', pageIndex: 1),
    (label: 'About', pageIndex: 4),
    (label: 'Settings', pageIndex: 3),
  ];

  static const List<({String label, IconData? iconData, String? assetPath})>
  _navItems = [
    (label: 'Home', iconData: null, assetPath: 'assets/icons/home-img.png'),
    (
      label: 'Bookmarks',
      iconData: null,
      assetPath: 'assets/icons/bookmark-img.png',
    ),
    (label: '', iconData: null, assetPath: 'assets/icons/mushaf-img-2.png'),
    (
      label: 'Settings',
      iconData: null,
      assetPath: 'assets/icons/settings-img.png',
    ),
    (label: 'About', iconData: null, assetPath: 'assets/icons/about-img.png'),
  ];

  static const List<Widget> _pages = [
    HomeScreen(),
    BookmarkScreen(),
    MushafLandingScreen(), // index 2
    SettingsScreen(),
    AboutScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final isMalayalam = (prefs.getString('app_language') ?? 'en') == 'ml';
      // ignore: use_build_context_synchronously
      final surahProvider = Provider.of<SurahProvider>(context, listen: false);
      await surahProvider.setMalayalam(isMalayalam);
      await surahProvider.getAllSurah();
      if (!mounted) return;

      final pendingRoute = app.pendingNotificationRoute;
      if (pendingRoute == null) {
        return;
      }

      app.pendingNotificationRoute = null;
      final handled = await app.handleNotificationRoute(pendingRoute);
      if (!handled) {
        app.pendingNotificationRoute = pendingRoute;
      }
    });
  }

  void _onItemTapped(int index) {
    Provider.of<HomeProvider>(context, listen: false).changeIndex(index);
    final screenNames = ['Home', 'Bookmarks', 'Mushaf', 'Settings', 'About Us'];
    // ignore: deprecated_member_use
    SemanticsService.announce(
      '${screenNames[index.clamp(0, 4)]} screen',
      TextDirection.ltr,
    );
  }

  void _setWebNavHovered(int pageIndex, bool hovered) {
    final isTracked = _hoveredWebNavItems.contains(pageIndex);
    if (isTracked == hovered) return;
    setState(() {
      if (hovered) {
        _hoveredWebNavItems.add(pageIndex);
      } else {
        _hoveredWebNavItems.remove(pageIndex);
      }
    });
  }

  double _navItemSize(int index) {
    // Render all bottom-nav icons at a single uniform size so no tab (e.g.
    // Settings) appears smaller than the others.
    return _navIconSize;
  }

  Widget _buildNavItemIcon({
    required int index,
    required Color color,
    required double size,
  }) {
    final item = _navItems[index];
    final iconData = item.iconData;
    if (iconData != null) {
      return Icon(iconData, size: size, color: color);
    }

    final assetPath = item.assetPath!;
    if (assetPath.endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Image.asset(assetPath, width: size, height: size, color: color);
  }

  bool _useWebShell(BuildContext context) {
    return kIsWeb;
  }

  Widget _buildWebNavButton({
    required int pageIndex,
    required String label,
    required int selectedIndex,
    required Color accentColor,
    bool compact = false,
  }) {
    final isSelected = pageIndex == selectedIndex;
    final isHovered = kIsWeb && _hoveredWebNavItems.contains(pageIndex);
    final showHoverBox = isHovered && !isSelected;
    final iconColor = accentColor.withValues(
      alpha: isSelected || isHovered ? 1.0 : 0.78,
    );
    final textColor = accentColor.withValues(
      alpha: isSelected || isHovered ? 1.0 : 0.90,
    );
    final hoverBackgroundColor = accentColor.withValues(alpha: 0.14);
    final hoverBorderColor = accentColor.withValues(alpha: 0.24);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label navigation item',
      child: InkWell(
        onTap: () => _onItemTapped(pageIndex),
        onHover: (hovered) => _setWebNavHovered(pageIndex, hovered),
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: accentColor.withValues(alpha: 0.10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 14,
            vertical: compact ? 3 : 10,
          ),
          decoration: BoxDecoration(
            color: showHoverBox ? hoverBackgroundColor : Colors.transparent,
            borderRadius: BorderRadius.circular(compact ? 16 : 18),
            border: Border.all(
              color: showHoverBox ? hoverBorderColor : Colors.transparent,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNavItemIcon(
                index: pageIndex,
                color: iconColor,
                size: _navItemSize(pageIndex) * (compact ? 0.72 : 0.95),
              ),
              SizedBox(height: compact ? 2 : 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: compact ? 10.5 : 13.5,
                  fontWeight: isSelected || isHovered
                      ? FontWeight.w700
                      : FontWeight.w500,
                ),
              ),
              SizedBox(height: compact ? 2 : 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: compact ? 1.5 : 2.5,
                width: isSelected ? (compact ? 18 : 28) : 0,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebToolbarActions(BuildContext context, int displayIndex) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isScrollableToolbar = screenWidth < 900;
    final navMaxWidth = (screenWidth * 0.24).clamp(180.0, 320.0).toDouble();
    const accentColor = AppTheme.appBarForegroundColor;

    final navRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        _webNavItems.length,
        (index) => _buildWebNavButton(
          pageIndex: _webNavItems[index].pageIndex,
          label: _webNavItems[index].label,
          selectedIndex: displayIndex,
          accentColor: accentColor,
          compact: true,
        ),
      ),
    );

    final trailingActions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          tooltip: 'Search',
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          onPressed: () => showSurahQuickSearchDialog(context),
        ),
        const SizedBox(width: 8),
        const AppBarLanguageButton(),
      ],
    );

    if (isScrollableToolbar) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              navRow,
              const SizedBox(width: 6),
              trailingActions,
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: navMaxWidth),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: navRow,
            ),
          ),
          const SizedBox(width: 6),
          trailingActions,
        ],
      ),
    );
  }

  Widget _buildWebReadModeToggle({
    required BuildContext context,
    required int displayIndex,
    required bool isMalayalam,
  }) {
    if (displayIndex != 0 && displayIndex != 2) {
      return const SizedBox.shrink();
    }

    const headerAccent = AppTheme.appThemePrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: ResponsiveContentWrapper(
        maxWidth: _webShellMaxWidth,
        child: Align(
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
                  _WebReadModeButton(
                    label: isMalayalam ? 'ഖുർആൻ വായനം' : 'Read Al-Qur\'an',
                    selected: displayIndex == 0,
                    onTap: () => _onItemTapped(0),
                  ),
                  const SizedBox(width: 4),
                  _WebReadModeButton(
                    label: isMalayalam ? 'മുഷ്ഹഫ്' : 'Read Mushaf',
                    selected: displayIndex == 2,
                    onTap: () => _onItemTapped(2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebShell(
    BuildContext context,
    Widget pageBody,
    int displayIndex,
    bool isMalayalam,
  ) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: displayIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onItemTapped(0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CommonAppBar.homeAppBar(
          context,
          showOrnament: false,
          actions: [_buildWebToolbarActions(context, displayIndex)],
        ),
        drawer: const CommonDrawer(),
        body: Column(
          children: [
            if (displayIndex == 2)
              _buildWebReadModeToggle(
                context: context,
                displayIndex: displayIndex,
                isMalayalam: isMalayalam,
              ),
            Expanded(child: pageBody),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<HomeProvider>(context);
    final theme = Theme.of(context);
    final bottomViewPadding = MediaQuery.viewPaddingOf(context).bottom;
    final isDarkMode = theme.brightness == Brightness.dark;
    final navBg = isDarkMode
        ? AppTheme.appThemePrimary
        : Colors.white; // AppTheme.appThemeSecondary;
    final navCornerFillColor = isDarkMode
        ? const Color(0xff0c2d52)
        : const Color.fromRGBO(255, 250, 234, 1);
    final inactiveColor = isDarkMode
        ? Colors.grey[400]!
        : const Color(0xFF4A4A4A);
    final displayIndex = controller.currentIndex;
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final tablet = ResponsiveHelper.isTablet(context);
    final scale = ResponsiveHelper.scaleFactor(context);
    final navCornerRadius = 28.0 * scale;

    final pageBody = IndexedStack(index: displayIndex, children: _pages);

    if (_useWebShell(context)) {
      return _buildWebShell(context, pageBody, displayIndex, isMalayalam);
    }

    final appBar = displayIndex == 0
        ? CommonAppBar.homeAppBar(context)
        : CommonAppBar.appBar(
            context,
            centerTitle: true,
            isActionsNeeded: displayIndex != 4 && displayIndex != 3,
            showLeading: true,
            isMalayalam: displayIndex == 4 && isMalayalam,
            title: [
              'Home',
              'Bookmarks',
              'Mushaf',
              'Settings',
              isMalayalam ? 'ഞങ്ങളെക്കുറിച്ച്' : 'About Us',
            ][displayIndex.clamp(0, 4)],
          );

    // ── Tablet: NavigationRail on the left ──
    if (tablet) {
      return PopScope(
        canPop: displayIndex == 0,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _onItemTapped(0);
        },
        child: Scaffold(
          key: _scaffoldKey,
          appBar: appBar,
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _onItemTapped(2);
            },
            child: Image.asset(
              _navItems[2].assetPath!,
              width: _navIconSize,
              height: _navIconSize,
              color: isDarkMode && displayIndex != 2
                  ? inactiveColor
                  : Colors.white,
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          drawer: const CommonDrawer(),
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: displayIndex,
                onDestinationSelected: _onItemTapped,
                backgroundColor: navBg,
                labelType: NavigationRailLabelType.all,
                selectedIconTheme: IconThemeData(
                  color: isDarkMode ? Colors.white : AppTheme.appIconTheme,
                  size: _navIconSize * scale,
                ),
                unselectedIconTheme: IconThemeData(
                  color: inactiveColor,
                  size: _navIconSize * scale,
                ),
                selectedLabelTextStyle: TextStyle(
                  color: isDarkMode ? Colors.white : AppTheme.appIconTheme,
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: inactiveColor,
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w400,
                ),
                destinations: List.generate(_navItems.length, (index) {
                  final item = _navItems[index];
                  return NavigationRailDestination(
                    icon: _buildNavItemIcon(
                      index: index,
                      color: inactiveColor,
                      size: _navItemSize(index) * scale,
                    ),
                    selectedIcon: item.label.isEmpty
                        ? SizedBox.square(
                            dimension: _navItemSize(index) * scale,
                          )
                        : _buildNavItemIcon(
                            index: index,
                            color: AppTheme.appIconTheme,
                            size: _navItemSize(index) * scale,
                          ),
                    label: Text(item.label),
                  );
                }),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: pageBody),
            ],
          ),
        ),
      );
    }

    // ── Phone: BottomNavigationBar ──
    return PopScope(
      canPop: displayIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onItemTapped(0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: appBar,
        floatingActionButton: Transform.translate(
          offset: Offset(0, 10 * scale),
          child: FloatingActionButton(
            onPressed: () {
              _onItemTapped(2);
            },
            child: Image.asset(
              _navItems[2].assetPath!,
              width: _navIconSize * scale,
              height: _navIconSize * scale,
              color: isDarkMode && displayIndex != 2
                  ? inactiveColor
                  : Colors.white,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        drawer: const CommonDrawer(),
        body: pageBody,
        bottomNavigationBar: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _NavCornerFillPainter(
                    color: navCornerFillColor,
                    radius: navCornerRadius,
                  ),
                ),
              ),
            ),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: navBg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(navCornerRadius),
                  topRight: Radius.circular(navCornerRadius),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  0,
                  6 * scale,
                  0,
                  bottomViewPadding + (6 * scale),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: List.generate(_navItems.length, (index) {
                        final item = _navItems[index];
                        final isSelected = displayIndex == index;
                        final isMushaf = index == 2;

                        final color = isMushaf
                            ? Colors.white
                            : isSelected
                            ? (isDarkMode
                                  ? Colors.white
                                  : AppTheme.appIconTheme)
                            : inactiveColor;

                        return Expanded(
                          child: Semantics(
                            button: true,
                            label:
                                '${item.label} tab${isSelected ? ', selected' : ''}',
                            excludeSemantics: true,
                            child: InkWell(
                              onTap: () => _onItemTapped(index),
                              borderRadius: BorderRadius.circular(10 * scale),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6 * scale,
                                  vertical: 4 * scale,
                                ),
                                margin: EdgeInsets.symmetric(
                                  horizontal: 4 * scale,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (item.label.isEmpty)
                                      SizedBox.square(
                                        dimension: _navItemSize(index) * scale,
                                      )
                                    else
                                      _buildNavItemIcon(
                                        index: index,
                                        color: color,
                                        size: _navItemSize(index) * scale,
                                      ),
                                    SizedBox(height: 3 * scale),
                                    Text(
                                      item.label,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 10 * scale,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WebReadModeButton extends StatelessWidget {
  const _WebReadModeButton({
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
            color: selected ? AppTheme.appThemePrimary : unselectedColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NavCornerFillPainter extends CustomPainter {
  const _NavCornerFillPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0 || size.width <= 0 || size.height <= 0) return;

    final wedgeExtent = radius.clamp(0.0, size.width / 2);
    final paint = Paint()..color = color;

    final leftSquare = Path()
      ..addRect(Rect.fromLTWH(0, 0, wedgeExtent, wedgeExtent));
    final leftCircle = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(wedgeExtent, wedgeExtent),
          radius: wedgeExtent,
        ),
      );
    final leftWedge = Path.combine(
      PathOperation.difference,
      leftSquare,
      leftCircle,
    );

    final rightSquare = Path()
      ..addRect(
        Rect.fromLTWH(size.width - wedgeExtent, 0, wedgeExtent, wedgeExtent),
      );
    final rightCircle = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width - wedgeExtent, wedgeExtent),
          radius: wedgeExtent,
        ),
      );
    final rightWedge = Path.combine(
      PathOperation.difference,
      rightSquare,
      rightCircle,
    );

    canvas.drawPath(leftWedge, paint);
    canvas.drawPath(rightWedge, paint);
  }

  @override
  bool shouldRepaint(_NavCornerFillPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
