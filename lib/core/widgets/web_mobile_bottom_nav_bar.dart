import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/link_hover/hover_link.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_screen_svg.dart';

/// Bottom navigation bar shown on mobile-width web views, using the same
/// icon assets as the native app's bottom nav (flat icons, no border/hover
/// chrome) plus a small label since this replaces the web appbar's labeled
/// toolbar buttons.
class WebMobileBottomNavBar extends StatelessWidget {
  const WebMobileBottomNavBar({
    super.key,
    required this.selectedPageIndex,
    required this.onPageSelected,
    this.onSearchPressed,
    this.isBookmarkNeeded = false,
    this.showSearch = false,
  });

  final int? selectedPageIndex;
  final ValueChanged<int> onPageSelected;
  final VoidCallback? onSearchPressed;
  final bool isBookmarkNeeded;
  final bool showSearch;

  static const double _navIconSize = 22;

  List<({String label, int? pageIndex, String? assetPath, bool isSearch})>
  get _items => [
    (label: 'Home', pageIndex: 0, assetPath: 'assets/icons/home-img.webp', isSearch: false),
    if (isBookmarkNeeded)
      (label: 'Bookmarks', pageIndex: 1, assetPath: 'assets/icons/bookmark-img.webp', isSearch: false),
    if (showSearch)
      (label: 'Search', pageIndex: null, assetPath: null, isSearch: true),
    (label: 'Settings', pageIndex: 3, assetPath: 'assets/icons/settings-img.webp', isSearch: false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final bottomViewPadding = MediaQuery.viewPaddingOf(context).bottom;
    final inactiveColor = isDarkMode
        ? Colors.grey[400]!
        : const Color(0xFF4A4A4A);
    final selectedColor = isDarkMode ? Colors.white : AppTheme.appIconTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: bottomViewPadding > 0 ? 0 : 6),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
          child: Row(
            children: [
              for (final item in _items)
                Expanded(
                  child: _NavBarButton(
                    label: item.label,
                    selected:
                        !item.isSearch && selectedPageIndex == item.pageIndex,
                    color:
                        (!item.isSearch && selectedPageIndex == item.pageIndex)
                        ? selectedColor
                        : inactiveColor,
                    iconSize: _navIconSize,
                    icon: item.isSearch ? null : item.assetPath,
                    isSearch: item.isSearch,
                    onTap: item.isSearch
                        ? (onSearchPressed ?? () {})
                        : () => onPageSelected(item.pageIndex!),
                    url: item.isSearch
                        ? null
                        : switch (item.pageIndex) {
                            0 => '/',
                            1 => '/bookmarks',
                            _ => null,
                          },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarButton extends StatelessWidget {
  const _NavBarButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.iconSize,
    required this.icon,
    required this.isSearch,
    required this.onTap,
    this.url,
  });

  final String label;
  final bool selected;
  final Color color;
  final double iconSize;
  final String? icon;
  final bool isSearch;
  final VoidCallback onTap;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final iconWidget = isSearch
        ? HomeScreenSvg(
            icon: 'search',
            color: color,
            width: iconSize,
            height: iconSize,
          )
        : Image.asset(icon!, width: iconSize, height: iconSize, color: color);

    final button = Semantics(
      button: true,
      label: '$label tab${selected ? ', selected' : ''}',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconWidget,
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    return url != null ? HoverLink(url: url!, child: button) : button;
  }
}
