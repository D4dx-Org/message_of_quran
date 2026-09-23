import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Body text in which plain URLs open externally and named phrases jump
/// somewhere inside the app.
///
/// [Linkify] only knows how to find URLs, but some of our copy also names a
/// destination in words — "DONATE NOW", "(Mus'haf)" — and those words should
/// be tappable too. Rather than nesting widgets and breaking the paragraph
/// flow, this builds one span tree per paragraph: URLs are matched the same
/// way Linkify matches them, and each key of [anchors] becomes a tappable
/// span running its callback.
///
/// Anchors are matched literally and case-sensitively, so a phrase that is not
/// present (the Malayalam copy, for instance) simply renders as plain text.
///
/// [boldPhrases] is matched differently: only a line consisting of nothing
/// but the phrase is bolded, not any occurrence of it inside a sentence --
/// otherwise a heading that repeats an ordinary word (e.g. "മലയാളം") would
/// bold that word everywhere it appears in the body text, not just where it
/// stands alone as a heading.
///
/// Lines starting with "• " render as an indented bullet with a hanging
/// indent (the marker sits in its own column so wrapped lines align under
/// the text, not under the bullet), matching how the source document
/// formats its lists rather than gluing the bullet glyph to flush-left text.
class LinkedBodyText extends StatefulWidget {
  const LinkedBodyText({
    super.key,
    required this.text,
    required this.style,
    required this.linkStyle,
    required this.onUrlTap,
    this.anchors = const {},
    this.boldPhrases = const {},
  });

  final String text;
  final TextStyle style;
  final TextStyle linkStyle;
  final void Function(String url) onUrlTap;
  final Map<String, VoidCallback> anchors;
  final Set<String> boldPhrases;

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

  static const _urlPattern = r'(?:https?://|www\.)[^\s,;)]+';
  static const _bulletPrefix = '• ';

  /// Builds spans for one line: URLs and [anchors] become tappable, and
  /// anything else renders as plain text in [style].
  List<InlineSpan> _lineSpans(String line) {
    final anchorPattern = widget.anchors.keys.map(RegExp.escape).join('|');
    final pattern = RegExp(
      anchorPattern.isEmpty ? _urlPattern : '$_urlPattern|$anchorPattern',
    );

    final spans = <InlineSpan>[];
    var index = 0;
    for (final match in pattern.allMatches(line)) {
      if (match.start > index) {
        spans.add(TextSpan(text: line.substring(index, match.start)));
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
    if (index < line.length) {
      spans.add(TextSpan(text: line.substring(index)));
    }
    return spans;
  }

  /// Joins a run of non-bullet lines back into one paragraph block, so blank
  /// lines between them still render as the blank-line gap they represent.
  Widget _paragraphBlock(List<String> lines) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (widget.boldPhrases.contains(line)) {
        spans.add(
          TextSpan(
            text: line,
            style: widget.style.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      } else {
        spans.addAll(_lineSpans(line));
      }
      if (i != lines.length - 1) {
        spans.add(const TextSpan(text: '\n'));
      }
    }
    return Text.rich(TextSpan(style: widget.style, children: spans));
  }

  Widget _bulletBlock(String content) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•', style: widget.style),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(style: widget.style, children: _lineSpans(content)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final lines = widget.text.split('\n');
    final blocks = <Widget>[];
    var paragraph = <String>[];

    void flushParagraph() {
      if (paragraph.isEmpty) return;
      blocks.add(_paragraphBlock(paragraph));
      paragraph = [];
    }

    for (final line in lines) {
      if (line.startsWith(_bulletPrefix)) {
        flushParagraph();
        blocks.add(_bulletBlock(line.substring(_bulletPrefix.length)));
      } else {
        paragraph.add(line);
      }
    }
    flushParagraph();

    // Text.rich, not SelectableText.rich: on Android touch, SelectableText's
    // own selection gesture wins the gesture arena over a span's embedded
    // TapGestureRecognizer, so links inside it silently stop registering
    // taps -- confirmed on-device (mouse clicks on web are unaffected,
    // which is why this slipped through until tested on a phone).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }
}
