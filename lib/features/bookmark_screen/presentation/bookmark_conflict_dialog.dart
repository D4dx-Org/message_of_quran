import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/models/ayah_bookmark_model.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';

enum BookmarkConflictResolution { replace, keepBoth }

String bookmarkTargetLabel(String navigationTarget) {
  return BookmarkNavigationTarget.normalize(navigationTarget) ==
          BookmarkNavigationTarget.mushaf
      ? 'Mushaf Block'
      : 'Quran Block';
}

Future<BookmarkConflictResolution?> showBookmarkConflictDialog(
  BuildContext context, {
  required String navigationTarget,
  required String? surahName,
}) {
  final sectionLabel = bookmarkTargetLabel(navigationTarget);
  final displaySurahName = surahName?.trim();
  final surahReference = displaySurahName != null && displaySurahName.isNotEmpty
      ? displaySurahName
      : 'this surah';

  return showDialog<BookmarkConflictResolution>(
    context: context,
    builder: (dialogContext) {
      final theme = Theme.of(dialogContext);
      final isDark = theme.brightness == Brightness.dark;
      final scale = ResponsiveHelper.scaleFactor(dialogContext);
      final accentColor = appBarAccentColor(dialogContext);
      final dialogMaxWidth =
          ResponsiveHelper.bottomSheetMaxWidth(dialogContext) ?? 420.0;
      final cardColor =
          theme.dialogTheme.backgroundColor ??
          (isDark ? const Color(0xff122f5a) : AppTheme.appThemeSecondary);
      final borderColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : AppTheme.appThemePrimary.withValues(alpha: 0.08);
      final outlineColor = theme.colorScheme.outline.withValues(
        alpha: isDark ? 0.4 : 0.55,
      );
      final titleStyle = AppTextTheme.popinsDefault(
        fontSize: 16.5 * scale,
        fontWeight: FontWeight.w700,
        color: accentColor,
      ).copyWith(height: 1.15);
      final bodyStyle = AppTextTheme.popinsDefault(
        fontSize: 13.5 * scale,
        color: theme.textTheme.bodyMedium?.color?.withValues(
          alpha: isDark ? 0.9 : 0.82,
        ),
      ).copyWith(height: 1.55);
      final buttonLabelStyle = AppTextTheme.popinsDefault(
        fontSize: 12.8 * scale,
        fontWeight: FontWeight.w600,
      );
      final buttonShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      );

      return Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: dialogMaxWidth),
          child: AlertDialog(
            backgroundColor: cardColor,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: borderColor),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
            contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            title: Row(
              children: [
                Container(
                  width: 40 * scale,
                  height: 40 * scale,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: isDark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.bookmark_added_rounded,
                    size: 20 * scale,
                    color: accentColor,
                  ),
                ),
                SizedBox(width: 12 * scale),
                Expanded(
                  child: Text(
                    'Bookmark already exists',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'You already saved a $sectionLabel bookmark in $surahReference. '
                  'Do you want to replace the existing bookmark or keep both?',
                  style: bodyStyle,
                ),
                SizedBox(height: 20 * scale),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(0, 46 * scale),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          foregroundColor: theme.textTheme.bodyMedium?.color,
                          side: BorderSide(color: outlineColor),
                          shape: buttonShape,
                          textStyle: buttonLabelStyle,
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(
                          dialogContext,
                        ).pop(BookmarkConflictResolution.keepBoth),
                        style: FilledButton.styleFrom(
                          minimumSize: Size(0, 46 * scale),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          backgroundColor: appBarAccentFillColor(
                            dialogContext,
                            alpha: isDark ? 0.22 : 0.12,
                          ),
                          foregroundColor: accentColor,
                          elevation: 0,
                          shape: buttonShape,
                          textStyle: buttonLabelStyle,
                        ),
                        child: const Text('Keep both'),
                      ),
                    ),
                    SizedBox(width: 8 * scale),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(
                          dialogContext,
                        ).pop(BookmarkConflictResolution.replace),
                        style: FilledButton.styleFrom(
                          minimumSize: Size(0, 46 * scale),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          backgroundColor: AppTheme.appThemePrimary,
                          foregroundColor: Colors.white,
                          shape: buttonShape,
                          textStyle: buttonLabelStyle,
                        ),
                        child: const Text('Replace'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
