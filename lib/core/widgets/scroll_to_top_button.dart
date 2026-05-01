import 'package:flutter/material.dart';

/// A floating action button that animates in/out based on [visible].
/// Tap it to invoke [onPressed] (typically animate the scroll controller to 0).
class ScrollToTopButton extends StatelessWidget {
  final bool visible;
  final VoidCallback onPressed;
  final String heroTag;

  const ScrollToTopButton({
    super.key,
    required this.visible,
    required this.onPressed,
    this.heroTag = 'scrollToTop',
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(
        ignoring: !visible,
        child: FloatingActionButton(
          heroTag: heroTag,
          mini: true,
          tooltip: 'Scroll to top',
          onPressed: onPressed,
          child: const Icon(Icons.keyboard_arrow_up_rounded),
        ),
      ),
    );
  }
}
