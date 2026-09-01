import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Body text in which plain URLs open externally and named phrases jump
/// somewhere inside the app.
///
/// [Linkify] only knows how to find URLs, but some of our copy also names a
/// destination in words — "DONATE NOW", "(Mus'haf)" — and those words should
/// be tappable too. Rather than nesting widgets and breaking the paragraph
/// flow, this builds one span tree: URLs are matched the same way Linkify
/// matches them, and each key of [anchors] becomes a tappable span running its
/// callback.
///
/// Anchors are matched literally and case-sensitively, so a phrase that is not
/// present (the Malayalam copy, for instance) simply renders as plain text.
class LinkedBodyText extends StatefulWidget {
  const LinkedBodyText({
    super.key,
    required this.text,
    required this.style,
    required this.linkStyle,
    required this.onUrlTap,
    this.anchors = const {},
  });

  final String text;
  final TextStyle style;
  final TextStyle linkStyle;
  final void Function(String url) onUrlTap;
  final Map<String, VoidCallback> anchors;

  @override
  State<LinkedBodyText> createState() => _LinkedBodyTextState();
}

class _LinkedBodyTextState extends State<LinkedBodyText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    const urlPattern = r'(?:https?://|www\.)[^\s,;)]+';
    final anchorPattern = widget.anchors.keys.map(RegExp.escape).join('|');
    final pattern = RegExp(
      anchorPattern.isEmpty ? urlPattern : '$urlPattern|$anchorPattern',
    );

    final spans = <InlineSpan>[];
    var index = 0;
    for (final match in pattern.allMatches(widget.text)) {
      if (match.start > index) {
        spans.add(TextSpan(text: widget.text.substring(index, match.start)));
      }
      final matched = match[0]!;
      final anchorTap = widget.anchors[matched];
      final recognizer = TapGestureRecognizer()
        ..onTap = anchorTap ?? () => widget.onUrlTap(matched);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: matched,
          style: widget.linkStyle,
          recognizer: recognizer,
        ),
      );
      index = match.end;
    }
    if (index < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(index)));
    }

    return SelectableText.rich(
      TextSpan(style: widget.style, children: spans),
    );
  }
}
