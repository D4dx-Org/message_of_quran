import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../provider/font_download_provider.dart';

/// Reusable dialog that downloads the Mushaf font pack (pages 3–604).
class MushafDownloadDialog extends StatefulWidget {
  const MushafDownloadDialog({
    super.key,
    required this.onSuccess,
    required this.onCancel,
  });

  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  @override
  State<MushafDownloadDialog> createState() => _MushafDownloadDialogState();
}

class _MushafDownloadDialogState extends State<MushafDownloadDialog> {
  late final FontDownloadProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = FontDownloadProvider();
    _provider.addListener(_onProviderChanged);
  }

  void _onProviderChanged() {
    if (_provider.isDone && mounted) {
      widget.onSuccess();
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: _DownloadDialogBody(onCancel: widget.onCancel),
    );
  }
}

class _DownloadDialogBody extends StatelessWidget {
  const _DownloadDialogBody({required this.onCancel});

  final VoidCallback onCancel;

  static const _primaryColor = AppTheme.appIconTheme;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FontDownloadProvider>();
    final progress = provider.progress;
    final error = provider.error;
    final isDownloading = provider.isDownloading;

    final percent =
        progress != null ? (progress * 100).toStringAsFixed(0) : null;

    return PopScope(
      canPop: !isDownloading,
      child: AlertDialog(
        title: const Text('Download Required'),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pages 1–2 are available offline.\n'
                'Download the Mushaf to read the full Quran.',
                style: TextStyle(fontSize: 14),
              ),
              if (progress != null) ...[
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  color: _primaryColor,
                ),
                const SizedBox(height: 6),
                Text(
                  progress < 1.0 ? 'Downloading… $percent%' : 'Verifying…',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(
                  error,
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isDownloading
                ? () {
                    provider.cancel();
                    onCancel();
                  }
                : onCancel,
            child: const Text('Cancel'),
          ),
          if (!isDownloading)
            ElevatedButton.icon(
              onPressed: () => provider.start(),
              icon: Icon(
                error != null ? Icons.refresh : Icons.download_rounded,
              ),
              label: Text(error != null ? 'Retry' : 'Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
