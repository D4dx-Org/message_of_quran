import 'package:flutter/material.dart';

import '../../../core/theme/app_text_theme.dart';
import '../../../core/theme/app_theme.dart';

class MushafDownloadRequiredDialog extends StatelessWidget {
  const MushafDownloadRequiredDialog({
    super.key,
    required this.onCancel,
    required this.onDownload,
  });

  final VoidCallback onCancel;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final titleIconColor = isDarkMode
        ? theme.colorScheme.onSurface
        : AppTheme.appIconTheme;
    final cancelActionColor = isDarkMode
        ? theme.colorScheme.onSurface.withValues(alpha: 0.78)
        : const Color(0xFF525866);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.download_rounded, color: titleIconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Download Required',
              style: AppTextTheme.popinsDefault(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      content: Text(
        'Pages 1–2 are available offline.\n'
        'Download the Mushaf font pack to read the full Quran.\n\n'
        'The download will continue in the background.',
        style: AppTextTheme.popinsDefault(fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text(
            'Cancel',
            style: AppTextTheme.popinsDefault(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: cancelActionColor,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: onDownload,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.appIconTheme,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Download',
            style: AppTextTheme.popinsDefault(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}