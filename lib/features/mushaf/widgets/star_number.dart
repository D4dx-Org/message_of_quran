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
            Container(
              width: size * 0.72,
              height: size * 0.72,
              decoration: const BoxDecoration(
                color: Color.fromRGBO(124, 58, 40, 1),
                shape: BoxShape.circle,
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
