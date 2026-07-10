import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/widgets/shimmer_asset_image.dart';

/// Image.asset wrapper for photo-style images: shows a tiny blurred
/// [thumbnailPath] instantly, then cross-fades to the full [assetPath]
/// image once it decodes.
///
/// Unlike [ShimmerAssetImage] (flat shimmer, for icons/logos), this gives
/// photographic images an actual low-res preview instead of a plain gray
/// box while the full-resolution asset loads.
class BlurUpAssetImage extends StatelessWidget {
  const BlurUpAssetImage({
    super.key,
    required this.assetPath,
    required this.thumbnailPath,
    this.width,
    this.height,
    this.aspectRatio,
    this.fit = BoxFit.cover,
    this.color,
    this.colorBlendMode,
    this.borderRadius,
    this.blurSigma = 12,
  });

  final String assetPath;
  final String thumbnailPath;
  final double? width;
  final double? height;

  /// width / height, used to derive the missing dimension when only one
  /// of [width]/[height] is given.
  final double? aspectRatio;
  final BoxFit fit;
  final Color? color;
  final BlendMode? colorBlendMode;
  final BorderRadius? borderRadius;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final resolvedSize = resolveAssetImageSize(
      width: width,
      height: height,
      aspectRatio: aspectRatio,
    );

    final content = Stack(
      fit: StackFit.expand,
      children: [
        ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Image.asset(
            thumbnailPath,
            fit: fit,
            color: color,
            colorBlendMode: colorBlendMode,
          ),
        ),
        Image.asset(
          assetPath,
          fit: fit,
          color: color,
          colorBlendMode: colorBlendMode,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return AnimatedOpacity(
              opacity: frame != null || wasSynchronouslyLoaded ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: child,
            );
          },
        ),
      ],
    );

    return SizedBox(
      width: resolvedSize.width,
      height: resolvedSize.height,
      child: borderRadius != null
          ? ClipRRect(borderRadius: borderRadius!, child: content)
          : content,
    );
  }
}
