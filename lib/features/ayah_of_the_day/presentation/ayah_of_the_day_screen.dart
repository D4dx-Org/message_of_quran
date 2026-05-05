import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/ayah_of_the_day/provider/ayah_of_the_day_provider.dart';
import 'package:the_message_of_the_quran/features/ayah_of_the_day/presentation/widgets/ayah_poster_widget.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';

class AyahOfTheDayScreen extends StatefulWidget {
  const AyahOfTheDayScreen({super.key});

  @override
  State<AyahOfTheDayScreen> createState() => _AyahOfTheDayScreenState();
}

class _AyahOfTheDayScreenState extends State<AyahOfTheDayScreen> {
  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AyahOfTheDayProvider>().loadTodaysAyah();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMl = context.watch<LanguageProvider>().isMalayalam;

    return BaseScreenLayout(
      appBar: AppBar(
        title: Semantics(
          header: true,
          child: Text(
            isMl ? 'ഇന്നത്തെ ആയത്ത്' : 'Ayah of the Day',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
          ),
        ),
        centerTitle: true,
      ),
      child: Consumer<AyahOfTheDayProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.appIconTheme,
              ),
            );
          }

          if (provider.error != null || provider.todaysAyah == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ExcludeSemantics(
                      child: Icon(Icons.error_outline, size: 48, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load today\'s ayah.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Semantics(
                      button: true,
                      label: 'Retry loading ayah of the day',
                      child: ElevatedButton(
                        onPressed: () => provider.loadTodaysAyah(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.appIconTheme,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                // ── Poster card with outlined frame ──
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.appIconTheme.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AyahPosterWidget(
                      ayah: provider.todaysAyah!,
                      repaintKey: _repaintKey,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Share as Poster button (gold) ──
                Semantics(
                  button: true,
                  label: provider.isSharing
                      ? 'Preparing poster for sharing'
                      : 'Share ayah as poster image',
                  enabled: !provider.isSharing,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: provider.isSharing
                          ? null
                          : () => provider.shareAsPoster(_repaintKey),
                      icon: provider.isSharing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.image_outlined, color: Colors.white),
                      label: Text(
                        provider.isSharing ? 'Preparing...' : 'Share as Poster',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.appIconTheme,
                        disabledBackgroundColor:
                            AppTheme.appIconTheme.withValues(alpha: 0.6),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Share as Text button (outlined gold) ──
                // SizedBox(
                //   width: double.infinity,
                //   child: OutlinedButton.icon(
                //     onPressed: () => provider.shareAsText(),
                //     icon: Icon(
                //       Icons.text_snippet_outlined,
                //       color: AppTheme.appIconTheme,
                //       size: 20,
                //     ),
                //     label: Text(
                //       'Share as Text',
                //       style: TextStyle(
                //         color: AppTheme.appIconTheme,
                //         fontWeight: FontWeight.w600,
                //       ),
                //     ),
                //     style: OutlinedButton.styleFrom(
                //       side: BorderSide(
                //         color: AppTheme.appIconTheme.withValues(alpha: 0.4),
                //       ),
                //       padding: const EdgeInsets.symmetric(vertical: 14),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ),
          );
        },
      ),
    );
  }
}
