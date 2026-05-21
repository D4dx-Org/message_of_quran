import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_list_tile.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/tajweed_provider.dart';

class SettingsScreenTajweedBlock extends StatelessWidget {
  const SettingsScreenTajweedBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final accentColor = appBarAccentColor(context);
    final accentTrackColor = appBarAccentFillColor(context, alpha: 0.35);

    return Consumer<TajweedProvider>(
      builder: (context, tajweed, _) {
        return SettingsScreenCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Tajweed mode toggle ──────────────────────────────────
              SettingsScreenListTile(
                title: 'Tajweed Quran',
                icon: Icons.color_lens_outlined,
                trailing: Switch(
                  value: tajweed.enabled,
                  activeThumbColor: accentColor,
                  activeTrackColor: accentTrackColor,
                  onChanged: (v) {
                    // Turning OFF while a download is active or paused → ask the user.
                    if (!v && (tajweed.isDownloading || tajweed.isDownloadPaused)) {
                      // Capture current state so dialog buttons behave correctly.
                      final wasPaused = tajweed.isDownloadPaused;
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Download in progress'),
                          content: const Text(
                            'What would you like to do with the Tajweed download?',
                          ),
                          actions: [
                            TextButton(
                              // From paused → resume; from downloading → just dismiss.
                              onPressed: () {
                                if (wasPaused) tajweed.resumeDownload();
                                Navigator.pop(ctx);
                              },
                              child: const Text('Keep Downloading'),
                            ),
                            TextButton(
                              // From downloading → pause; from paused → already paused, just dismiss.
                              onPressed: () {
                                if (!wasPaused) tajweed.pauseDownload();
                                Navigator.pop(ctx);
                              },
                              child: const Text('Pause'),
                            ),
                            TextButton(
                              onPressed: () {
                                tajweed.setEnabled(false);
                                Navigator.pop(ctx);
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Cancel Download'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      tajweed.setEnabled(v);
                    }
                  },
                ),
              ),

              // ── Download progress / status ───────────────────────────
              if (tajweed.enabled) ...[
                if (tajweed.isExtracting) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: tajweed.extractTotalFiles > 0
                              ? tajweed.extractProgress
                              : null,
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                          color: accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tajweed.extractTotalFiles > 0
                              ? 'Extracting images ... '
                                  '${(tajweed.extractProgress * 100).toStringAsFixed(0)}%'
                              : 'Extracting images ...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                ] else if (tajweed.isDownloading) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: tajweed.downloadProgress,
                          backgroundColor:
                              Theme.of(context).colorScheme.surfaceContainerHighest,
                          color: accentColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Downloading tajweed ... '
                          '${(tajweed.downloadProgress * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                        ),
                      ],
                    ),
                  ),
                ] else if (tajweed.isDownloadPaused) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.pause_circle_outline,
                          size: 16,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: IgnorePointer(
                            child: Text(
                              'Download paused',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: tajweed.resumeDownload,
                          style: TextButton.styleFrom(
                            foregroundColor: accentColor,
                            textStyle: AppTextTheme.popinsDefault(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: const Text('Resume'),
                        ),
                      ],
                    ),
                  ),
                ] else if (tajweed.downloadComplete) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 16,
                          color: accentColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tajweed Enabled',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: accentColor,
                              ),
                        ),
                      ],
                    ),
                  ),
                ] else if (tajweed.downloadError != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 16,
                          color: Colors.red,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tajweed.downloadError!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.red),
                          ),
                        ),
                        TextButton(
                          onPressed: tajweed.retryDownload,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Enabled but not yet started — will be triggered automatically.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Text(
                      'Preparing download…',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
