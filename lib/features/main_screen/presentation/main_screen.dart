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
import 'package:the_message_of_the_quran/features/search_screen/presentation/search_screen.dart';
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
  static const double _navIconSize = 24;
  static const double _webShellMaxWidth = 1180;

  static const List<({String label, IconData? iconData, String? assetPath})>
  _navItems = [
    (label: 'Home', iconData: null, assetPath: 'assets/icons/home-img.png'),
    (
      label: 'Bookmarks',
      iconData: null,
      assetPath: 'assets/icons/bookmark-img.png',
    ),
    (
      label: '',
      iconData: null,
      assetPath: 'assets/icons/mushaf-img-2.png',
    ),
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

  double _navItemSize(int index) {
    return switch (index) {
      0 || 3 => _navIconSize - 4,
      1 => _navIconSize - 1,
      _ => _navIconSize,
    };
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
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      color: color,
    );
  }

  bool _useWebShell(BuildContext context) {
    return kIsWeb;
  }

  Widget _buildWebNavButton({
    required int index,
    required String label,
    required int selectedIndex,
    required Color accentColor,
  }) {
    final isSelected = index == selectedIndex;
    final iconColor = accentColor.withValues(alpha: isSelected ? 1.0 : 0.78);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label navigation item',
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNavItemIcon(
                index: index,
                color: iconColor,
                size: _navItemSize(index) * 0.95,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 2.5,
                width: isSelected ? 28 : 0,
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

  Widget _buildWebShell(BuildContext context, Widget pageBody, int displayIndex) {
    final navLabels = const ['Home', 'Bookmarks', 'Mushaf', 'Settings', 'About'];
    final theme = Theme.of(context);
    final shellColor = AppTheme.appThemePrimary;
    final accentColor = AppTheme.appBarForegroundColor;
    final outlineColor = Colors.black.withValues(alpha: 0.10);
    final actionSurface = accentColor.withValues(alpha: 0.10);

    return PopScope(
      canPop: displayIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onItemTapped(0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.scaffoldBackgroundColor,
        drawer: const CommonDrawer(),
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: ResponsiveContentWrapper(
                  maxWidth: _webShellMaxWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: shellColor,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: outlineColor,
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isCompactShell = constraints.maxWidth < 980;
                          final hideHeaderLogo = constraints.maxWidth < 720;

                          Widget buildMenuButton() {
                            return Builder(
                              builder: (context) => DecoratedBox(
                                decoration: BoxDecoration(
                                  color: actionSurface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.18),
                                  ),
                                ),
                                child: IconButton(
                                  tooltip: 'Open menu',
                                  onPressed: () => Scaffold.of(context).openDrawer(),
                                  icon: const Icon(Icons.menu, color: Colors.white),
                                ),
                              ),
                            );
                          }

                          Widget buildSearchButton() {
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: actionSurface,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.18),
                                ),
                              ),
                              child: IconButton(
                                tooltip: 'Search',
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SearchScreen(),
                                  ),
                                ),
                                icon: const Icon(Icons.search, color: Colors.white),
                              ),
                            );
                          }

                          Widget buildLeadingGroup() {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                buildMenuButton(),
                                const SizedBox(width: 16),
                                Image.asset(
                                  'assets/images/Group-logo.png',
                                  height: 40,
                                  fit: BoxFit.contain,
                                  semanticLabel: 'Quran Asad Malayalam logo',
                                ),
                              ],
                            );
                          }

                          Widget buildTrailingGroup() {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                buildSearchButton(),
                                const SizedBox(width: 12),
                                AppBarLanguageButton(),
                              ],
                            );
                          }

                          Widget buildNavScroller({required bool centerItems}) {
                            final navRow = Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                navLabels.length,
                                (index) => _buildWebNavButton(
                                  index: index,
                                  label: navLabels[index],
                                  selectedIndex: displayIndex,
                                  accentColor: accentColor,
                                ),
                              ),
                            );

                            if (!centerItems) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: navRow,
                              );
                            }

                            return Center(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: navRow,
                              ),
                            );
                          }

                          if (isCompactShell) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    buildMenuButton(),
                                    const Spacer(),
                                    buildSearchButton(),
                                    const SizedBox(width: 12),
                                    AppBarLanguageButton(),
                                  ],
                                ),
                                if (!hideHeaderLogo) ...[
                                  const SizedBox(height: 14),
                                  Image.asset(
                                    'assets/images/Group-logo.png',
                                    height: 34,
                                    fit: BoxFit.contain,
                                    semanticLabel: 'Quran Asad Malayalam logo',
                                  ),
                                ],
                                const SizedBox(height: 16),
                                buildNavScroller(centerItems: false),
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: buildLeadingGroup(),
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 2,
                                child: buildNavScroller(centerItems: true),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: buildTrailingGroup(),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
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
    final inactiveColor = isDarkMode ? Colors.grey[400]! : const Color(0xFF4A4A4A);
    final displayIndex = controller.currentIndex;
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final tablet = ResponsiveHelper.isTablet(context);
    final scale = ResponsiveHelper.scaleFactor(context);
      final navCornerRadius = 28.0 * scale;

    final pageBody = IndexedStack(index: displayIndex, children: _pages);

      if (_useWebShell(context)) {
        return _buildWebShell(context, pageBody, displayIndex);
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
              isMalayalam
                  ? 'ഞങ്ങളെക്കുറിച്ച്'
                  : 'About Us',
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
              color: isDarkMode && displayIndex != 2 ? inactiveColor : Colors.white,
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
              color: isDarkMode && displayIndex != 2 ? inactiveColor : Colors.white,
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
                            ? (isDarkMode ? Colors.white : AppTheme.appIconTheme)
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
        Rect.fromLTWH(
          size.width - wedgeExtent,
          0,
          wedgeExtent,
          wedgeExtent,
        ),
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
