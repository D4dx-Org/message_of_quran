import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Wraps [child] with two-finger pinch-to-zoom (visual magnification), without
/// stealing single-finger gestures from an inner scrollable / [PageView].
///
/// Behaviour:
///  * At rest (scale == 1) a single-finger drag is ignored by this widget and
///    passes straight through to [child] — so an inner `ScrollView` keeps
///    scrolling and a surrounding `PageView` keeps swiping.
///  * A two-finger pinch scales [child] about the gesture focal point, and the
///    same two fingers can move the magnified content around.
///  * While zoomed in (scale > 1) a single-finger drag pans the magnified
///    content.
///  * Pinching back in clamps smoothly to the normal (identity) view and
///    re-enables normal scrolling / swiping.
///
/// [child] is expected to fill the available space (the zoom math assumes the
/// content size equals the viewport size, which is the case for a scroll view
/// or a page that expands to its parent's constraints).
class PinchZoomView extends StatefulWidget {
  const PinchZoomView({super.key, required this.child, this.maxScale = 4.0});

  final Widget child;

  /// Largest magnification factor allowed.
  final double maxScale;

  @override
  State<PinchZoomView> createState() => _PinchZoomViewState();
}

class _PinchZoomViewState extends State<PinchZoomView> {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Size _viewport = Size.zero;

  // Gesture start bookkeeping.
  double _startScale = 1.0;
  // The child-space point that sits under the gesture focal point when the
  // gesture begins; kept fixed under the fingers while scaling.
  Offset _scenePoint = Offset.zero;

  static const double _epsilon = 1e-3;

  bool get _isZoomed => _scale > 1.0 + _epsilon;

  void _onStart(ScaleStartDetails details) {
    _startScale = _scale;
    _scenePoint = (details.localFocalPoint - _offset) / _scale;
  }

  void _onUpdate(ScaleUpdateDetails details) {
    final newScale = (_startScale * details.scale).clamp(1.0, widget.maxScale);
    final newOffset = newScale <= 1.0 + _epsilon
        ? Offset.zero
        : _clampOffset(
            details.localFocalPoint - _scenePoint * newScale,
            newScale,
          );
    setState(() {
      _scale = newScale;
      _offset = newOffset;
    });
  }

  Offset _clampOffset(Offset offset, double scale) {
    if (_viewport == Size.zero) return offset;
    final minX = _viewport.width * (1 - scale);
    final minY = _viewport.height * (1 - scale);
    return Offset(
      offset.dx.clamp(minX, 0.0),
      offset.dy.clamp(minY, 0.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _viewport = constraints.biggest;
        return RawGestureDetector(
          behavior: HitTestBehavior.translucent,
          gestures: {
            _ZoomScaleGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<_ZoomScaleGestureRecognizer>(
                  () => _ZoomScaleGestureRecognizer(
                    debugOwner: this,
                    allowSingleFinger: () => _isZoomed,
                  ),
                  (recognizer) {
                    recognizer
                      ..onStart = _onStart
                      ..onUpdate = _onUpdate;
                  },
                ),
          },
          child: ClipRect(
            child: Transform(
              transform: Matrix4.identity()
                ..translateByDouble(_offset.dx, _offset.dy, 0, 1)
                ..scaleByDouble(_scale, _scale, 1, 1),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// A [ScaleGestureRecognizer] that only claims the gesture arena with two or
/// more pointers, unless [allowSingleFinger] currently returns true (used to
/// allow one-finger panning while the view is already zoomed in). This keeps
/// single-finger scrolling / page-swiping working when the view is at rest.
class _ZoomScaleGestureRecognizer extends ScaleGestureRecognizer {
  _ZoomScaleGestureRecognizer({
    super.debugOwner,
    required this.allowSingleFinger,
  });

  final bool Function() allowSingleFinger;

  @override
  void resolve(GestureDisposition disposition) {
    if (disposition == GestureDisposition.accepted &&
        pointerCount < 2 &&
        !allowSingleFinger()) {
      return;
    }
    super.resolve(disposition);
  }
}
