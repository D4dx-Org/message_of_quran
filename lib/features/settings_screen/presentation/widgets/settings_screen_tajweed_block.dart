import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
              // Toggle
              SettingsScreenListTile(
                title: 'Tajweed Quran',
                icon: Icons.color_lens_outlined,
                trailing: Switch(
                  value: tajweed.enabled,
                  activeThumbColor: accentColor,
                  activeTrackColor: accentTrackColor,
                  onChanged: tajweed.isDownloading
                      ? null
                      : (v) => _onToggle(context, tajweed, v),
                ),
              ),

              // Download progress
              if (tajweed.isDownloading) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: tajweed.downloadProgress,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(tajweed.downloadProgress * 100).toStringAsFixed(0)}%',
                            style:
                                Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Downloading Tajweed fonts…',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                      TextButton(
                        onPressed: () => tajweed.cancelDownload(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),
              ],

              // Error state
              if (!tajweed.isDownloading && tajweed.downloadError != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Colors.red),
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
                        onPressed: () => tajweed.retryDownload(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],

              // Enabled + installed state
              if (tajweed.enabled && tajweed.fontsInstalled && !tajweed.isDownloading) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 16, color: accentColor),
                      const SizedBox(width: 6),
                      Text(
                        'Font-based Tajweed active',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: accentColor),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _confirmDelete(context, tajweed),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Remove fonts'),
                      ),
                    ],
                  ),
                ),
              ],

              // Fonts installed but Tajweed off
              if (!tajweed.enabled && tajweed.fontsInstalled && !tajweed.isDownloading) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        'Fonts installed',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _confirmDelete(context, tajweed),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('Remove fonts'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _onToggle(
    BuildContext context,
    TajweedProvider tajweed,
    bool value,
  ) async {
    if (!value) {
      await tajweed.setEnabled(false);
      return;
    }

    // Check if fonts already installed.
    final alreadyInstalled = tajweed.fontsInstalled;
    if (alreadyInstalled) {
      await tajweed.setEnabled(true);
      return;
    }

    // Prompt user to download the font pack.
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Download Tajweed Fonts'),
        content: const Text(
          'This downloads 604 page fonts (~180 MB) for font-based Tajweed '
          'rendering in the Mushaf reader.\n\nProceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await tajweed.startDownload();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TajweedProvider tajweed,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Tajweed Fonts'),
        content: const Text(
          'This will delete all 604 downloaded Tajweed font files and disable '
          'Tajweed mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await tajweed.deleteFontPack();
    }
  }
}
