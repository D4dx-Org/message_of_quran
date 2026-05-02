import 'dart:math' as math;

import 'package:flutter/material.dart';

class StarNumber extends StatelessWidget {
  final int number;
  final double size;
  final bool isHighlighted;

  const StarNumber({
    super.key,
    required this.number,
    this.size = 40,
    this.isHighlighted = false,
    // Kept for backward compatibility but ignored:
    bool outlineOnly = false,
    Color color = const Color.fromARGB(255, 218, 218, 218),
    Color textColor = const Color.fromARGB(255, 0, 0, 0),
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final Color polygonColor;
    final Color fgColor;

    if (isHighlighted) {
      polygonColor = const Color.fromRGBO(124, 58, 40, 1);
      fgColor = Colors.white;
    } else {
      polygonColor = const Color.fromRGBO(124, 58, 40, 1);
      fgColor =
          isDarkMode ? Colors.white : const Color.fromRGBO(124, 58, 40, 1);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isHighlighted)
            CustomPaint(
              size: Size(size, size),
              painter: _HexagonPainter(
                color: polygonColor,
                radius: size * 0.50,
              ),
            ),
          Image.asset(
            'assets/icons/Polygon 2.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            color: polygonColor,
            colorBlendMode: BlendMode.srcIn,
          ),
          Text(
            number.toString(),
            style: TextStyle(
              color: fgColor,
              fontWeight: FontWeight.w500,
              fontSize: size * 0.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color color;
  final double radius;

  _HexagonPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3) * i - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HexagonPainter oldDelegate) =>
      color != oldDelegate.color || radius != oldDelegate.radius;
}
