import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Image.asset wrapper that shows a same-sized shimmer placeholder until
/// the asset's first frame decodes, then cross-fades to the real image.
///
/// Web fetches asset bytes over HTTP at runtime, so a cold cache can show a
/// brief pop-in after surrounding layout has already rendered. Provide
/// [width] and/or [height]; if only one is given, [aspectRatio]
/// (width / height) derives the other so the placeholder never collapses to
/// zero size and the layout doesn't shift once the image loads.
class ShimmerAssetImage extends StatelessWidget {
  const ShimmerAssetImage(
    this.assetPath, {
    super.key,
    this.width,
    this.height,
    this.aspectRatio,
    this.fit = BoxFit.contain,
    this.color,
    this.colorBlendMode,
    this.filterQuality = FilterQuality.low,
    this.cacheHeight,
    this.semanticLabel,
    this.borderRadius,
  }) : assert(
         width != null || height != null,
         'Provide width and/or height (with aspectRatio if only one is given)',
       ),
       assert(
         (width != null && height != null) || aspectRatio != null,
         'aspectRatio is required when only width or only height is given',
       );

  final String assetPath;
  final double? width;
  final double? height;

  /// width / height, used to derive the missing dimension when only one
  /// of [width]/[height] is given.
  final double? aspectRatio;
  final BoxFit fit;
  final Color? color;
  final BlendMode? colorBlendMode;
  final FilterQuality filterQuality;
  final int? cacheHeight;
  final String? semanticLabel;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolvedWidth = width ?? (height! * aspectRatio!);
    final resolvedHeight = height ?? (width! / aspectRatio!);

    final image = Image.asset(
      assetPath,
      width: resolvedWidth,
      height: resolvedHeight,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      filterQuality: filterQuality,
      cacheHeight: cacheHeight,
      semanticLabel: semanticLabel,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: frame == null
              ? ShimmerBox(
                  key: const ValueKey('shimmer'),
                  width: resolvedWidth,
                  height: resolvedHeight,
                  borderRadius: borderRadius,
                )
              : KeyedSubtree(key: const ValueKey('image'), child: child),
        );
      },
    );

    return SizedBox(
      width: resolvedWidth,
      height: resolvedHeight,
      child: borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: image)
          : image,
    );
  }
}

/// Standalone shimmering placeholder box, sized to [width]x[height].
/// Used internally by [ShimmerAssetImage] and reusable wherever a shimmer
/// placeholder is needed independent of an actual image (e.g. a combined
/// placeholder covering more than one image).
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: borderRadius ?? BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
