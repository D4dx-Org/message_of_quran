import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/widgets/link_hover/link_hover_controller.dart';

/// Wraps a link-triggering widget so hovering it (web/desktop only) reports
/// [url] to the app-wide [LinkHoverController], which [LinkStatusBar] reads
/// to show a browser-style link preview bottom-left.
class HoverLink extends StatelessWidget {
  const HoverLink({super.key, required this.url, required this.child});

  final String url;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    final controller = context.read<LinkHoverController>();
    return MouseRegion(
      onEnter: (_) => controller.show(url),
      onExit: (_) => controller.hide(),
      child: child,
    );
  }
}
