import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/constants/app_constants.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/app_bar_language_button.dart';
import 'package:the_message_of_the_quran/core/widgets/app_bar_theme_button.dart';
import 'package:the_message_of_the_quran/core/widgets/shimmer_asset_image.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_screen_svg.dart';
import 'package:the_message_of_the_quran/features/search_screen/presentation/widgets/surah_quick_search.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/settings_screen.dart';

class CommonWebAppBarActions extends StatefulWidget {
  const CommonWebAppBarActions({
    super.key,
    this.selectedPageIndex,
    required this.onPageSelected,
    this.onSearchPressed,
    this.compact = true,
    this.showSearch = true,
    this.showLabels = true,
    this.isBookmarkNeeded = true,
  });

  final int? selectedPageIndex;
  final ValueChanged<int> onPageSelected;
  final VoidCallback? onSearchPressed;
  final bool compact;
  final bool showSearch;
  final bool showLabels;
  final bool isBookmarkNeeded;

  @override
  State<CommonWebAppBarActions> createState() => _CommonWebAppBarActionsState();
}

class _CommonWebAppBarActionsState extends State<CommonWebAppBarActions> {
  bool get isBookmarkNeed => widget.isBookmarkNeeded;

  List<({String label, int pageIndex, String assetPath})> get _navItems => [
    (label: 'Home', pageIndex: 0, assetPath: 'assets/icons/home-img.png'),

    // Clean, direct Collection-If implementation
    if (isBookmarkNeed)
      (
        label: 'Bookmarks',
        pageIndex: 1,
        assetPath: 'assets/icons/bookmark-img.png',
      ),

    (
      label: 'Settings',
      pageIndex: 3,
      assetPath: 'assets/icons/settings-img.png',
    ),
  ];

  final Set<int> _hoveredPageIndices = <int>{};
  bool _isSearchHovered = false;
  bool _isThemeHovered = false;

  void _setHoveredPage(int pageIndex, bool hovered) {
    final isTracked = _hoveredPageIndices.contains(pageIndex);
    if (isTracked == hovered) return;

    setState(() {
      if (hovered) {
        _hoveredPageIndices.add(pageIndex);
      } else {
        _hoveredPageIndices.remove(pageIndex);
      }
    });
  }

  void _setSearchHovered(bool hovered) {
    if (_isSearchHovered == hovered) return;
    setState(() {
      _isSearchHovered = hovered;
    });
  }

  void _setThemeHovered(bool hovered) {
    if (_isThemeHovered == hovered) return;
    setState(() {
      _isThemeHovered = hovered;
    });
  }

  Widget _buildToolbarButton({
    required String label,
    required Widget icon,
    required bool isSelected,
    required bool isHovered,
    required VoidCallback onTap,
    required ValueChanged<bool> onHover,
  }) {
    const accentColor = AppTheme.appBarForegroundColor;
    final compact = widget.compact;
    final showHoverBox = isHovered && !isSelected;
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
        onTap: onTap,
        onHover: onHover,
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
              icon,
              if (widget.showLabels) SizedBox(height: compact ? 2 : 8),
              if (widget.showLabels)
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
              if (widget.showLabels) SizedBox(height: compact ? 2 : 8),
              if (!widget.showLabels) const SizedBox(height: 2),
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

  @override
  Widget build(BuildContext context) {
    const accentColor = AppTheme.appBarForegroundColor;
    final compact = widget.compact;
    final iconSize = AppConstants.appBarIconWidth * (compact ? 0.72 : 0.95);
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    // Nav + search icons relocate to a bottom nav bar on mobile-width web
    // views, matching the native app's bottom nav instead of the desktop
    // toolbar button style.
    final isMobileWidth = MediaQuery.sizeOf(context).width < 640;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isMobileWidth) ...[
          for (final item in _navItems)
            _buildToolbarButton(
              label: item.label,
              isSelected: widget.selectedPageIndex == item.pageIndex,
              isHovered: _hoveredPageIndices.contains(item.pageIndex),
              onTap: () => widget.onPageSelected(item.pageIndex),
              onHover: (hovered) => _setHoveredPage(item.pageIndex, hovered),
              icon: Image.asset(
                item.assetPath,
                width: iconSize,
                height: iconSize,
                color: accentColor.withValues(
                  alpha:
                      widget.selectedPageIndex == item.pageIndex ||
                          _hoveredPageIndices.contains(item.pageIndex)
                      ? 1.0
                      : 0.78,
                ),
              ),
            ),
          if (widget.showSearch)
            _buildToolbarButton(
              label: 'Search',
              isSelected: false,
              isHovered: _isSearchHovered,
              onTap:
                  widget.onSearchPressed ??
                  () => showSurahQuickSearchDialog(context),
              onHover: _setSearchHovered,
              icon: HomeScreenSvg(
                icon: 'search',
                color: accentColor.withValues(
                  alpha: _isSearchHovered ? 1.0 : 0.78,
                ),
                width: iconSize,
                height: iconSize,
              ),
            ),
        ],
        _buildToolbarButton(
          label: isDark ? 'Light' : 'Dark',
          isSelected: false,
          isHovered: _isThemeHovered,
          onTap: () => themeProvider.toggleTheme(),
          onHover: _setThemeHovered,
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: iconSize,
            color: accentColor.withValues(alpha: _isThemeHovered ? 1.0 : 0.78),
          ),
        ),
        const SizedBox(width: 6),
        AppBarLanguageButton(showText: widget.showLabels, iconSize: iconSize),
      ],
    );
  }
}

class CommonAppBar {
  CommonAppBar._();

  // Temporary A/B switch for app bar logo clarity testing.
  // Change this constant to compare both rendering modes.
  static const _appBarLogoClarityMode = _AppBarLogoClarityMode.highQuality;

  static Widget _brandLogoTapTarget(
    BuildContext context, {
    double? height,
    VoidCallback? onTap,
  }) {
    final scale = ResponsiveHelper.scaleFactor(context);
    final logoHeight = height ?? 40 * scale;
    const isHighQualityMode =
        _appBarLogoClarityMode == _AppBarLogoClarityMode.highQuality;
    const appBarLogoFilterQuality = isHighQualityMode
        ? FilterQuality.high
        : FilterQuality.medium;
    final cacheHeight = isHighQualityMode
        ? null
        : (logoHeight * MediaQuery.devicePixelRatioOf(context)).round();
    final image = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ShimmerAssetImage(
          'assets/images/symbol-logo.png',
          height: logoHeight,
          aspectRatio: 165 / 276,
          filterQuality: appBarLogoFilterQuality,
          cacheHeight: cacheHeight,
          semanticLabel: 'Quran Asad Malayalam logo symbol',
        ),
        SizedBox(width: 2 * scale),
        ShimmerAssetImage(
          'assets/images/symbol-logo-text.png',
          height: logoHeight,
          aspectRatio: 258 / 154,
          filterQuality: appBarLogoFilterQuality,
          cacheHeight: cacheHeight,
          semanticLabel: 'Quran Asad Malayalam logo text',
        ),
      ],
    );
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap ?? () => context.go('/'),
        child: image,
      ),
    );
  }

  static Widget brandLogo(
    BuildContext context, {
    Alignment alignment = Alignment.centerLeft,
    double? height,
    VoidCallback? onTap,
  }) {
    return Align(
      alignment: alignment,
      child: _brandLogoTapTarget(context, height: height, onTap: onTap),
    );
  }

  static Widget _drawerMenuButton(BuildContext context) {
    final scale = ResponsiveHelper.scaleFactor(context);
    return Semantics(
      button: true,
      label: 'Open navigation menu',
      child: IconButton(
        icon: Image.asset(
          'assets/images/menu-icon-new.png',
          height: AppConstants.appBarIconHeight * scale,
          width: AppConstants.appBarIconWidth * scale,
          fit: BoxFit.contain,
        ),
        onPressed: () => Scaffold.of(context).openDrawer(),
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Primary-themed app bar for the home screen matching the current brand.
  static PreferredSizeWidget homeAppBar(
    BuildContext ctx, {
    bool showOrnament = true,
    String title = "",
    TextStyle? titleStyle,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
  }) {
    final scale = ResponsiveHelper.scaleFactor(ctx);
    final ornamentTop = -48.0 * scale;
    final ornamentOverflow = 75.0 * scale;
    final ornamentWidth = 137.0 * scale;
    final ornamentHeight = 146.0 * scale;
    const edgePadding = 5.0;
    final leadingWidth = (46 * scale).roundToDouble() + edgePadding;
    final hasTitleText = title.isNotEmpty;
    final resolvedActions = <Widget>[
      ...actions ?? [_buildAppendixWebActions(ctx)],
      const SizedBox(width: edgePadding),
    ];

    final flexibleSpaceChildren = <Widget>[
      if (showOrnament)
        PositionedDirectional(
          top: ornamentTop,
          end: -ornamentOverflow,
          child: Image.asset(
            'assets/images/home_side_image.png',
            width: ornamentWidth,
            height: ornamentHeight,
            fit: BoxFit.contain,
            color: AppTheme.appThemeRawChips,
            colorBlendMode: BlendMode.srcIn,
          ),
        ),
      // Positioned outside the title slot so it can't rob centerTitle of the
      // slack it needs to truly center the title text.
      if (hasTitleText)
        PositionedDirectional(
          start: leadingWidth + NavigationToolbar.kMiddleSpacing,
          top: 0,
          bottom: 0,
          child: Center(child: _brandLogoTapTarget(ctx)),
        ),
    ];

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.appThemePrimary,
      elevation: 0,
      clipBehavior: Clip.none,
      flexibleSpace: flexibleSpaceChildren.isEmpty
          ? null
          : Stack(clipBehavior: Clip.none, children: flexibleSpaceChildren),
      leadingWidth: leadingWidth,
      title: hasTitleText
          ? Text(title, style: titleStyle ?? AppTextTheme.titleRegular)
          : Stack(
              alignment: AlignmentGeometry.center,
              children: [
                brandLogo(ctx),
                const SizedBox(width: 8),
                Text(title, style: titleStyle ?? AppTextTheme.titleRegular),
              ],
            ),
      centerTitle: true,
      leading: Builder(
        builder: (context) => Padding(
          padding: const EdgeInsetsDirectional.only(start: edgePadding),
          child: _drawerMenuButton(context),
        ),
      ),
      actions: resolvedActions,
      bottom: bottom,
    );
  }

  static Widget _buildAppendixWebActions(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 640;
    final actions = CommonWebAppBarActions(
      isBookmarkNeeded: false,
      selectedPageIndex: null,
      onPageSelected: (index) {
        if (index == 3) {
          showSettingsDialog(context);
          return;
        }
        context.go('/');
      },
      compact: true,
      showSearch: false,
      showLabels: !isNarrow,
      onSearchPressed: () {},
    );
    return Padding(padding: const EdgeInsets.only(right: 8), child: actions);
  }

  static PreferredSizeWidget appBar(
    BuildContext ctx, {
    bool isActionsNeeded = true,
    bool showLeading = true,
    bool showBrandLogo = false,
    bool centerTitle = false,
    String? title,
    bool isMalayalam = false,
    Widget? titleWidget,
    VoidCallback? onSurahInfoTap,
    List<Widget>? actions,
    bool showSearch = true,
  }) {
    final scale = ResponsiveHelper.scaleFactor(ctx);
    final resolvedActions =
        actions ??
        (isActionsNeeded
            ? [
                if (onSurahInfoTap != null)
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/revamp/surah_info_icon.svg',
                      height: AppConstants.appBarIconHeight,
                      width: AppConstants.appBarIconWidth,
                      fit: BoxFit.scaleDown,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                    tooltip: 'Surah Info',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: onSurahInfoTap,
                  ),
                const AppBarThemeToggleButton(),
                const SizedBox(width: 4),
                const AppBarLanguageButton(),
                const SizedBox(width: 8),
                if (showSearch)
                  IconButton(
                    icon: const HomeScreenSvg(
                      icon: 'search',
                      color: Colors.white,
                    ),
                    tooltip: 'Search',
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    onPressed: () => showSurahQuickSearchDialog(ctx),
                  ),
                if (showSearch) const SizedBox(width: 8),
              ]
            : null);

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppTheme.appThemePrimary,
      elevation: 0,
      leadingWidth: showLeading ? (46 * scale).roundToDouble() : null,
      titleSpacing: showBrandLogo ? 0 : NavigationToolbar.kMiddleSpacing,
      title:
          titleWidget ??
          (showBrandLogo
              ? brandLogo(ctx)
              : (title != null
                    ? Text(
                        title,
                        style: AppTextTheme.localizedTitle(
                          isMalayalam: isMalayalam,
                          fontSize: 18 * scale,
                          fontWeight: FontWeight.w600,
                          color: appBarTitleMatchedAccentColor(ctx),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null)),
      centerTitle: showBrandLogo ? false : centerTitle,
      leading: showLeading
          ? Builder(builder: (context) => _drawerMenuButton(context))
          : null,
      actions: resolvedActions,
    );
  }
}

enum _AppBarLogoClarityMode { mediumWithCache, highQuality }
