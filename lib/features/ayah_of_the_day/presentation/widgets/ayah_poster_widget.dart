import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/ayah_of_the_day/data/ayah_of_the_day_model.dart';

class AyahPosterWidget extends StatelessWidget {
  const AyahPosterWidget({
    super.key,
    required this.ayah,
    required this.repaintKey,
  });

  final AyahOfTheDayModel ayah;
  final GlobalKey repaintKey;

  static const Color _gold = AppTheme.appIconTheme;
  static const Color _bg = AppTheme.appThemeSecondary;
  static const Color _textDark = Color(0xFF1C1C1E);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ayah of the Day. ${ayah.surahNameArabic}, Ayah ${ayah.ayahNo}. '
          '${ayah.arabicText}. '
          'Translation: ${ayah.translationText}',
      readOnly: true,
      child: RepaintBoundary(
        key: repaintKey,
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: _bg,
          ),
          child: CustomPaint(
            painter: _IslamicPatternPainter(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTopLabel(),
                    const SizedBox(height: 16),
                    Text(
                      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Uthmani',
                        fontSize: 14,
                        color: _gold.withValues(alpha: 0.55),
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _OrnamentalDivider(),
                    const SizedBox(height: 20),
                    Text(
                      ayah.arabicText,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'Uthmani',
                        fontSize: 24,
                        color: _textDark,
                        height: 2.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const _OrnamentalDivider(),
                    const SizedBox(height: 16),
                    Text(
                      ayah.translationText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSansMalayalam(
                        fontSize: 13,
                        color: _textDark.withValues(alpha: 0.78),
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.08),
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${ayah.surahNameArabic}  ┃  Ayah ${ayah.ayahNo}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _gold,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildGoldLine(50),
                    const SizedBox(height: 8),
                    Text(
                      'വിശുദ്ധ ഖുര്‍ആന്‍ വിവര്‍ത്തനം',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: _gold.withValues(alpha: 0.5),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopLabel() {
    return Column(
      children: [
        _buildGoldLine(40),
        const SizedBox(height: 8),
        Text(
          'AYAH OF THE DAY',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _gold,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        _buildGoldLine(40),
      ],
    );
  }

  Widget _buildGoldLine(double width) {
    return Container(
      width: width,
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _gold.withValues(alpha: 0.0),
            _gold.withValues(alpha: 0.5),
            _gold.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

class _OrnamentalDivider extends StatelessWidget {
  const _OrnamentalDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 16,
      child: CustomPaint(painter: _DividerPainter()),
    );
  }
}

class _DividerPainter extends CustomPainter {
  static const _gold = AyahPosterWidget._gold;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          _gold.withValues(alpha: 0.0),
          _gold.withValues(alpha: 0.5),
          _gold.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, cy - 0.5, size.width, 1))
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, cy), Offset(cx - 12, cy), linePaint);
    canvas.drawLine(Offset(cx + 12, cy), Offset(size.width, cy), linePaint);
    final diamondPaint = Paint()
      ..color = _gold.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final diamond = Path()
      ..moveTo(cx, cy - 4)
      ..lineTo(cx + 4, cy)
      ..lineTo(cx, cy + 4)
      ..lineTo(cx - 4, cy)
      ..close();
    canvas.drawPath(diamond, diamondPaint);
    final dotPaint = Paint()..color = _gold.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(cx - 10, cy), 1.2, dotPaint);
    canvas.drawCircle(Offset(cx + 10, cy), 1.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IslamicPatternPainter extends CustomPainter {
  static const _gold = AyahPosterWidget._gold;

  @override
  void paint(Canvas canvas, Size size) {
    _drawRadialGlow(canvas, size);
    _drawDoubleBorder(canvas, size);
    _drawCornerStars(canvas, size);
    _drawEdgeAccents(canvas, size);
  }

  void _drawRadialGlow(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.6,
        colors: [
          _gold.withValues(alpha: 0.06),
          _gold.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  void _drawDoubleBorder(Canvas canvas, Size size) {
    final outerPaint = Paint()
      ..color = _gold.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(10, 10, size.width - 20, size.height - 20),
        const Radius.circular(12),
      ),
      outerPaint,
    );
    final innerPaint = Paint()
      ..color = _gold.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(16, 16, size.width - 32, size.height - 32),
        const Radius.circular(8),
      ),
      innerPaint,
    );
  }

  void _drawCornerStars(Canvas canvas, Size size) {
    final positions = [
      const Offset(10, 10),
      Offset(size.width - 10, 10),
      Offset(size.width - 10, size.height - 10),
      Offset(10, size.height - 10),
    ];
    for (final pos in positions) {
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      _drawEightPointStar(canvas, 30, _gold.withValues(alpha: 0.12));
      _drawEightPointStar(canvas, 18, _gold.withValues(alpha: 0.18));
      _drawEightPointStar(canvas, 9, _gold.withValues(alpha: 0.25));
      canvas.restore();
    }
  }

  void _drawEightPointStar(Canvas canvas, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4) - math.pi / 2;
      final ox = radius * math.cos(angle);
      final oy = radius * math.sin(angle);
      final innerAngle = angle + math.pi / 8;
      final ir = radius * 0.38;
      final ix = ir * math.cos(innerAngle);
      final iy = ir * math.sin(innerAngle);
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawEdgeAccents(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _gold.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    final cx = size.width / 2;
    canvas.drawLine(Offset(cx - 35, 10), Offset(cx - 12, 10), paint);
    canvas.drawLine(Offset(cx + 12, 10), Offset(cx + 35, 10), paint);
    _drawSmallDiamond(canvas, Offset(cx, 10), 3);
    final by = size.height - 10;
    canvas.drawLine(Offset(cx - 35, by), Offset(cx - 12, by), paint);
    canvas.drawLine(Offset(cx + 12, by), Offset(cx + 35, by), paint);
    _drawSmallDiamond(canvas, Offset(cx, by), 3);
    final midY = size.height / 2;
    canvas.drawLine(Offset(10, midY - 20), Offset(10, midY - 8), paint);
    canvas.drawLine(Offset(10, midY + 8), Offset(10, midY + 20), paint);
    _drawSmallDiamond(canvas, Offset(10, midY), 2.5);
    final rx = size.width - 10;
    canvas.drawLine(Offset(rx, midY - 20), Offset(rx, midY - 8), paint);
    canvas.drawLine(Offset(rx, midY + 8), Offset(rx, midY + 20), paint);
    _drawSmallDiamond(canvas, Offset(rx, midY), 2.5);
  }

  void _drawSmallDiamond(Canvas canvas, Offset center, double r) {
    final paint = Paint()
      ..color = _gold.withValues(alpha: 0.30)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..lineTo(center.dx + r, center.dy)
      ..lineTo(center.dx, center.dy + r)
      ..lineTo(center.dx - r, center.dy)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
