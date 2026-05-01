import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';

/// Wraps its [child] in a centered, width-constrained box on tablets/desktops.
/// On phones the child renders at full width with no overhead.
class ResponsiveContentWrapper extends StatelessWidget {
  const ResponsiveContentWrapper({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  final Widget child;

  /// Override the default max-width from [ResponsiveHelper.contentMaxWidth].
  final double? maxWidth;

  /// Optional horizontal padding applied inside the constraint.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectiveMax = maxWidth ?? ResponsiveHelper.contentMaxWidth(context);

    if (effectiveMax == double.infinity && padding == null) {
      return child;
    }

    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMax),
        child: content,
      ),
    );
  }
}
