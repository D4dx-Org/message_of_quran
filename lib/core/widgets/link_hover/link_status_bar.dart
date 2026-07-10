import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/widgets/link_hover/link_hover_controller.dart';

/// Browser-style strip pinned bottom-left showing the URL under the cursor.
/// Must be a direct child of a [Stack] (it returns a [Positioned]).
class LinkStatusBar extends StatelessWidget {
  const LinkStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final url = context.watch<LinkHoverController>().hoveredUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: 0,
      bottom: 0,
      child: IgnorePointer(
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          offset: url == null ? const Offset(0, 1) : Offset.zero,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 120),
            opacity: url == null ? 0 : 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2B2B2B) : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.16)
                        : Colors.black.withValues(alpha: 0.16),
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  url ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
