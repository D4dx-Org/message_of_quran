import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/widgets/link_hover/hover_link.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/last_read_provider.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/reading_progress_provider.dart';

class HomeScreenBanner extends StatelessWidget {
  const HomeScreenBanner({super.key, this.isLandscape = false});
  final bool isLandscape;

  void _navigateToLastRead(BuildContext context) {
    final lastRead = context.read<LastReadProvider>();
    if (!lastRead.hasLastRead) return;

    final surahNum = lastRead.surahNumber;
    if (surahNum == null) return;
    context.push('/surah/$surahNum?scrollToAyahId=${lastRead.ayahId}');
  }

  @override
  Widget build(BuildContext context) {
    final scale = ResponsiveHelper.scaleFactor(context);
    return Padding(
        padding: EdgeInsets.fromLTRB(16 * scale, 12 * scale, 16 * scale, 4),
        child: Consumer2<LastReadProvider, ReadingProgressProvider>(
          builder: (context, lastRead, readingProgress, _) {
            final surahNum = lastRead.surahNumber;
            final progress = surahNum != null
                ? readingProgress.surahProgress(surahNum)
                : 0.0;
            final progressPct = (progress * 100).toStringAsFixed(0);
            final lastReadTitle = lastRead.hasLastRead
                ? '${lastRead.surahNumber}. ${lastRead.surahName}'
                : 'Start Reading';
            final lastReadTitleUsesMalayalamFont = RegExp(
              r'[\u0D00-\u0D7F]',
            ).hasMatch(lastReadTitle);

            final card = Semantics(
              button: lastRead.hasLastRead,
              label: lastRead.hasLastRead
                  ? 'Last Read: Surah ${lastRead.surahName}, Ayah ${lastRead.ayahId}, $progressPct percent complete'
                  : 'Start reading the Quran',
              hint: lastRead.hasLastRead ? 'Double tap to continue reading' : null,
              excludeSemantics: true,
              child: GestureDetector(
              onTap: lastRead.hasLastRead
                  ? () => _navigateToLastRead(context)
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Background image
                    if (isLandscape)
                      SizedBox.expand(
                        child: Image.asset(
                          'assets/images/banner.png',
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      AspectRatio(
                        aspectRatio: 16 / 7,
                        child: Image.asset(
                          'assets/images/banner.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    // Gradient overlay
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppTheme.appThemePrimary.withValues(alpha: 0.88),
                              AppTheme.appThemePrimary.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Content
                    Positioned(
                      left: 20 * scale,
                      top: 5,
                      bottom: 5,
                      right: 20 * scale,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // App Name at the top (hidden in landscape to save space)
                                if (!isLandscape)
                                  Text(
                                    'വിശുദ്ധ ഖുര്‍ആന്‍ വിവര്‍ത്തനം',
                                    style: AppTextTheme.localizedLabel(
                                      isMalayalam: true,
                                      color: Colors.white,
                                      fontSize: 18 * scale,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                Row(
                                  spacing: 6,
                                  children: [
                                    const Icon(
                                      Icons.menu_book_rounded,
                                      color: Colors.white70,
                                      size: 14,
                                    ),
                                    Text(
                                      'Last Read',
                                      style: AppTextTheme.popinsDefault(
                                        color: Colors.white
                                            .withValues(alpha: 0.8),
                                        fontSize: 12 * scale,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  lastReadTitle,
                                  style: AppTextTheme.localizedLabel(
                                    isMalayalam:
                                        lastReadTitleUsesMalayalamFont,
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (lastRead.hasLastRead) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Ayah ${lastRead.ayahId}',
                                    style: AppTextTheme.popinsDefault(
                                      color: Colors.white
                                          .withValues(alpha: 0.75),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (lastRead.hasLastRead)
                            SizedBox(
                              width: 52 * scale,
                              height: 52 * scale,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 4 * scale,
                                    backgroundColor: Colors.white
                                        .withValues(alpha: 0.2),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                  Center(
                                    child: Text(
                                      '$progressPct%',
                                      style: AppTextTheme.popinsDefault(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              ),
            );

            return lastRead.hasLastRead
                ? HoverLink(
                    url:
                        '/surah/${lastRead.surahNumber}?scrollToAyahId=${lastRead.ayahId}',
                    child: card,
                  )
                : card;
          },
        ),
    );
  }
}

