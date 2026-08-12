import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/core/utils/surah_place_localizer.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/last_read_provider.dart';

class AppBarModelSheet {
  AppBarModelSheet._();

  static Future<void> modelSheet(BuildContext ctx) {
    final surahProvider = Provider.of<SurahProvider>(ctx, listen: false);
    final maxWidth = ResponsiveHelper.bottomSheetMaxWidth(ctx);
    return showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      constraints: maxWidth != null
          ? BoxConstraints(maxWidth: maxWidth)
          : null,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: surahProvider,
        child: _JumpToSheet(navCtx: ctx),
      ),
    );
  }
}

// ─── Private stateful sheet ───────────────────────────────────────────────────

class _JumpToSheet extends StatefulWidget {
  const _JumpToSheet({required this.navCtx});

  /// Outer context used to push the SurahScreen after the sheet closes.
  final BuildContext navCtx;

  @override
  State<_JumpToSheet> createState() => _JumpToSheetState();
}

class _JumpToSheetState extends State<_JumpToSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _loading = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _ensureSurahsLoaded();
  }

  Future<void> _ensureSurahsLoaded() async {
    final provider = Provider.of<SurahProvider>(context, listen: false);
    if (provider.surahList.isEmpty) {
      setState(() => _loading = true);
      await provider.getAllSurah();
      if (mounted) setState(() => _loading = false);
    }
  }

  List<SurahModel> _filtered(List<SurahModel> all) {
    if (_query.isEmpty) return all;
    final q = _query.trim().toLowerCase();
    return all.where((s) {
      return s.name.toLowerCase().contains(q) ||
          s.arabicName.contains(_query.trim()) ||
          s.surahNumber.toString() == q;
    }).toList();
  }

  void _onSurahTap(SurahModel surah) {
    if (_navigating) return;
    _navigating = true;

    // Check if we're already on a route above root (i.e. on SurahScreen).
    final isOnRoot = ModalRoute.of(widget.navCtx)?.isFirst ?? true;

    // Close the bottom sheet first.
    if (mounted) Navigator.pop(context);

    if (!widget.navCtx.mounted) return;

    if (isOnRoot) {
      // On home screen — push a fresh SurahScreen and update the Surah tab
      // highlight (only relevant when the user is navigating from the Surah
      // home tab; updating it from a Juz-opened reader would contaminate the
      // Surah tab's independent selection state).
      Provider.of<LastReadProvider>(
        widget.navCtx,
        listen: false,
      ).saveLastSurahTabSelection(surah.surahNumber);

      widget.navCtx.push('/surah/${surah.surahNumber}');
    } else {
      // Already on SurahScreen — re-invoke the same route with the new
      // surahNumber; go_router rebuilds SurahRouteResolver in place (no new
      // page pushed) which re-resolves SurahProvider and reloads ayahs.
      // Do NOT update lastSurahTabSelection here: the user is jumping surahs
      // inside the reader (possibly from the Juz tab), so the Surah tab's
      // independent highlight must not be affected.
      widget.navCtx.go('/surah/${surah.surahNumber}');
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppTheme.appThemePrimary;
    final subColor = isDark ? Colors.white54 : Colors.grey[600]!;
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final scale = ResponsiveHelper.scaleFactor(context);
    return Consumer<SurahProvider>(
      builder: (_, provider, _) {
        final all = provider.surahList;
        final filtered = _filtered(all);

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          expand: false,
          builder: (_, scrollCtrl) {
            return Column(
              children: [
                // ── Drag handle ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 4),
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // ── Title ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Jump to Surah',
                    style: AppTextTheme.popinsDefault(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // ── Search field ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search by name or number…',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                const Divider(height: 1),
                // ── Surah list ────────────────────────────────────────
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                      ? Center(
                          child: Text(
                            _query.isEmpty
                                ? 'Loading surahs…'
                                : 'No surah found for "$_query"',
                            style: AppTextTheme.popinsDefault(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.separated(
                          controller: scrollCtrl,
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1, indent: 72),
                          itemBuilder: (_, i) {
                            final surah = filtered[i];
                            final displayText = formatSurahListDisplayText(
                              isMalayalam: isMalayalam,
                              surahName: surah.name,
                              surahTranslation: surah.description,
                              malayalamName: surah.malayalamName,
                              surahNumber: surah.surahNumber,
                            );
                            final displayName = displayText.title;
                            final description = displayText.subtitle;
                            final placeName = localizeSurahPlace(
                              surah.place,
                              isMalayalam: isMalayalam,
                            );
                            final ayahLabel = formatAyahCountLabel(
                              surah.ayathCount,
                              isMalayalam: isMalayalam,
                            );
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppTheme.appThemePrimary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${surah.surahNumber}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              title: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextTheme.localizedLabel(
                                  isMalayalam: isMalayalam,
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12 * scale,
                                ),
                              ),
                              subtitle: description.isNotEmpty
                                  ? Text(
                                      description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextTheme.localizedBody(
                                        isMalayalam: isMalayalam,
                                        fontSize: 11 * scale,
                                        color: subColor,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: 0.2,
                                      ),
                                    )
                                  : null,
                              trailing: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    placeName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: AppTextTheme.localizedLabel(
                                      isMalayalam: isMalayalam,
                                      color: subColor,
                                      fontSize: 11 * scale,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    ayahLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: AppTextTheme.localizedLabel(
                                      isMalayalam: isMalayalam,
                                      fontSize: 10.5 * scale,
                                      color: subColor,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () => _onSurahTap(surah),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
