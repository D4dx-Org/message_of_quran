import 'package:flutter/material.dart';

class StarNumber extends StatelessWidget {
  final int number;
  final double size;

  const StarNumber({
    super.key,
    required this.number,
    this.size = 40,
    // Kept for backward compatibility but ignored:
    bool isHighlighted = false,
    bool outlineOnly = false,
    Color color = const Color.fromARGB(255, 218, 218, 218),
    Color textColor = const Color.fromARGB(255, 0, 0, 0),
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fgColor =
        isDarkMode ? Colors.white : const Color.fromRGBO(124, 58, 40, 1);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/icons/Polygon 2.png',
            width: size,
            height: size,
            fit: BoxFit.contain,
            color: const Color.fromRGBO(124, 58, 40, 1),
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
