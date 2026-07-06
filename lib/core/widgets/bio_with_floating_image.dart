import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_message_of_the_quran/core/widgets/blur_up_asset_image.dart';

/// Renders [imagePath] floated top-left with [bioText] wrapping beside it
/// for as many lines as fit within the image's height, then continuing
/// full-width below — like a book/article layout.
///
/// WidgetSpan-in-RichText only reserves inline space on the single line
/// it's placed on, not across the image's full height, so it can't do
/// this on its own. Instead we measure the text with a TextPainter to
/// find the line boundary at the image's height, and split there.
class BioWithFloatingImage extends StatefulWidget {
  final String imagePath;
  final String thumbnailPath;
  final String bioText;
  final TextStyle textStyle;
  final double imageWidth;
  final double imageHeight;

  const BioWithFloatingImage({
    super.key,
    required this.imagePath,
    required this.thumbnailPath,
    required this.bioText,
    required this.textStyle,
    this.imageWidth = 200,
    this.imageHeight = 200,
  });

  @override
  State<BioWithFloatingImage> createState() => _BioWithFloatingImageState();
}

class _BioWithFloatingImageState extends State<BioWithFloatingImage> {
  static const double _gap = 12;

  @override
  void initState() {
    super.initState();
    // On web, Google Fonts load asynchronously. If the TextPainter split
    // below runs against the fallback font's metrics, the rendered text
    // re-wraps once the real font arrives and spills past the image. Wait a
    // frame (so this screen's styles have registered their font fetches),
    // then re-run the split when every pending font has loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GoogleFonts.pendingFonts().then((_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.imagePath;
    final thumbnailPath = widget.thumbnailPath;
    final bioText = widget.bioText;
    final textStyle = widget.textStyle;
    final imageWidth = widget.imageWidth;
    final imageHeight = widget.imageHeight;
    final image = Padding(
      padding: const EdgeInsets.only(right: _gap, bottom: 8),
      child: BlurUpAssetImage(
        assetPath: imagePath,
        thumbnailPath: thumbnailPath,
        width: imageWidth,
        height: imageHeight,
        borderRadius: BorderRadius.circular(12),
      ),
    );

    if (bioText.isEmpty) {
      return image;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wrapWidth =
            (constraints.maxWidth - imageWidth - _gap).clamp(0.0, constraints.maxWidth);

        TextPainter measure(String s) => TextPainter(
              text: TextSpan(text: s, style: textStyle),
              textDirection: Directionality.of(context),
              textScaler: MediaQuery.textScalerOf(context),
            )..layout(maxWidth: wrapWidth);

        final fullPainter = measure(bioText);

        // Initial guess: what text sits above the image's bottom edge.
        var floatedText = fullPainter.height <= imageHeight
            ? bioText
            : bioText.substring(
                0,
                fullPainter
                    .getLineBoundary(
                        fullPainter.getPositionForOffset(Offset(0, imageHeight)))
                    .end,
              );
        floatedText = floatedText.trimRight();

        // Validate against floatedText's own rendered height at this width
        // — line-height math drifts across scripts/widths, so back off a
        // line at a time until it actually fits. This is the only way to
        // guarantee the real SelectableText won't spill past the image.
        while (floatedText.isNotEmpty) {
          final p = measure(floatedText);
          if (p.height <= imageHeight) break;
          final lines = p.computeLineMetrics();
          if (lines.length <= 1) {
            floatedText = '';
            break;
          }
          final lastLineTop =
              p.height - lines.last.height + lines.last.height / 2;
          final lastLineStart = p
              .getLineBoundary(p.getPositionForOffset(Offset(0, lastLineTop)))
              .start;
          floatedText = floatedText.substring(0, lastLineStart).trimRight();
        }

        // Orphan pass: a trailing line holding a single word looks broken
        // beside the photo — push whole such lines down into the full-width
        // text instead.
        while (floatedText.isNotEmpty) {
          final p = measure(floatedText);
          final lines = p.computeLineMetrics();
          if (lines.length <= 1) break;
          final lastLineTop =
              p.height - lines.last.height + lines.last.height / 2;
          final lastLineStart = p
              .getLineBoundary(p.getPositionForOffset(Offset(0, lastLineTop)))
              .start;
          final lastLine = floatedText.substring(lastLineStart).trim();
          if (lastLine.contains(' ')) break;
          floatedText = floatedText.substring(0, lastLineStart).trimRight();
        }

        final restText = bioText.substring(floatedText.length).trimLeft();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image,
                Expanded(
                  child: SelectableText(
                    floatedText,
                    style: textStyle,
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
            if (restText.isNotEmpty)
              SelectableText(
                restText,
                style: textStyle,
                textAlign: TextAlign.justify,
              ),
          ],
        );
      },
    );
  }
}
