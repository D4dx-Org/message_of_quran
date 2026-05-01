import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class AppBarModelSheet {
  AppBarModelSheet._();

  static Future<void> modelSheet(BuildContext ctx) {
    final surahProvider = Provider.of<SurahProvider>(ctx, listen: false);
    return showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
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

  Future<void> _onSurahTap(SurahModel surah) async {
    if (_navigating) return;
    _navigating = true;

    final provider = Provider.of<SurahProvider>(context, listen: false);

    // Check if we're already on a route above root (i.e. on SurahScreen).
    final isOnRoot = ModalRoute.of(widget.navCtx)?.isFirst ?? true;

    // Close the bottom sheet first.
    if (mounted) Navigator.pop(context);

    // Load the new surah data (sets provider index + fetches translations/ayahs).
    await provider.selectSurahByNumber(surah.surahNumber);

    if (!widget.navCtx.mounted) return;

    if (isOnRoot) {
      // On home screen — push a fresh SurahScreen.
      Navigator.push(
        widget.navCtx,
        MaterialPageRoute(builder: (_) => const SurahScreen()),
      );
    }
    // If already on SurahScreen, it rebuilds automatically via its Provider
    // listener — no extra navigation needed (avoids double-jump).
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Jump to Surah',
                    style: TextStyle(
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
                          vertical: 10, horizontal: 12),
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
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.separated(
                              controller: scrollCtrl,
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const Divider(height: 1, indent: 72),
                              itemBuilder: (_, i) {
                                final surah = filtered[i];
                                return ListTile(
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: AppTheme.appThemePrimary,
                                      borderRadius:
                                          BorderRadius.circular(8),
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
                                    surah.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    ' ${surah.ayathCount}  Ayat .   ${surah.arabicName} ',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade100,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      surah.place,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF9C5A20),
                                      ),
                                    ),
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
