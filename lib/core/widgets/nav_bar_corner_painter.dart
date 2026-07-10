import 'package:flutter/material.dart';

/// Paints the concave corner fill behind a rounded-top bottom nav bar so the
/// screen background shows through as a smooth curve into the bar's corners.
class NavBarCornerFillPainter extends CustomPainter {
  const NavBarCornerFillPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0 || size.width <= 0 || size.height <= 0) return;

    final wedgeExtent = radius.clamp(0.0, size.width / 2);
    final paint = Paint()..color = color;

    final leftSquare = Path()
      ..addRect(Rect.fromLTWH(0, 0, wedgeExtent, wedgeExtent));
    final leftCircle = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(wedgeExtent, wedgeExtent),
          radius: wedgeExtent,
        ),
      );
    final leftWedge = Path.combine(
      PathOperation.difference,
      leftSquare,
      leftCircle,
    );

    final rightSquare = Path()
      ..addRect(
        Rect.fromLTWH(size.width - wedgeExtent, 0, wedgeExtent, wedgeExtent),
      );
    final rightCircle = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width - wedgeExtent, wedgeExtent),
          radius: wedgeExtent,
        ),
      );
    final rightWedge = Path.combine(
      PathOperation.difference,
      rightSquare,
      rightCircle,
    );

    canvas.drawPath(leftWedge, paint);
    canvas.drawPath(rightWedge, paint);
  }

  @override
  bool shouldRepaint(NavBarCornerFillPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
