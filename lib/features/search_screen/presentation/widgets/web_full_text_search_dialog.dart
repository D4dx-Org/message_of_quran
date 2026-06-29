import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/interpretation_search_result_model.dart';
import 'package:the_message_of_the_quran/core/models/verse_search_result_model.dart';
import 'package:the_message_of_the_quran/core/services/database/interpretations_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/translation_block_db_helper.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry point
// ─────────────────────────────────────────────────────────────────────────────

/// Opens the full-text search dialog for web.
///
/// After the dialog is dismissed with a navigation target the caller pushes
/// to [SurahScreen] so that [context] (from the main scaffold) remains valid.
Future<void> showWebFullTextSearchDialog(BuildContext context) async {
  final surahProv = context.read<SurahProvider>();

  final target = await showDialog<_NavTarget>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const _WebFullTextSearchDialog(),
  );

  if (target == null || !context.mounted) return;

  if (surahProv.surahList.isEmpty) await surahProv.getAllSurah();
  if (!context.mounted) return;

  final idx = surahProv.surahList.indexWhere(
    (s) => s.surahNumber == target.surahNumber,
  );
  if (idx < 0) return;

  surahProv.assignIndex(idx);
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SurahScreen(
        scrollToAyahId: target.verseNumber > 0 ? target.verseNumber : null,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal navigation result
// ─────────────────────────────────────────────────────────────────────────────

class _NavTarget {
  const _NavTarget({required this.surahNumber, required this.verseNumber});
  final int surahNumber;
  final int verseNumber;
}

// ─────────────────────────────────────────────────────────────────────────────
// Search type enum
// ─────────────────────────────────────────────────────────────────────────────

enum _SearchType { translation, interpretation, arabic }

// ─────────────────────────────────────────────────────────────────────────────
// Dialog widget
// ─────────────────────────────────────────────────────────────────────────────

class _WebFullTextSearchDialog extends StatefulWidget {
  const _WebFullTextSearchDialog();

  @override
  State<_WebFullTextSearchDialog> createState() =>
      _WebFullTextSearchDialogState();
}

class _WebFullTextSearchDialogState extends State<_WebFullTextSearchDialog> {
  _SearchType _searchType = _SearchType.translation;
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<VerseSearchResultModel> _verseResults = [];
  List<InterpretationSearchResultModel> _interpretationResults = [];
  List<VerseSearchResultModel> _arabicResults = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // ── search ────────────────────────────────────────────────────────────────

  void _onQueryChanged(String value, bool isMalayalam) {
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _verseResults = [];
        _interpretationResults = [];
        _arabicResults = [];
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _runSearch(q, isMalayalam),
    );
  }

  Future<void> _runSearch(String q, bool isMalayalam) async {
    if (!mounted) return;
    if (_searchType == _SearchType.translation) {
      final results = await TranslationBlockDbHelper.searchVersesByWord(
        q,
        isMalayalam: isMalayalam,
      );
      if (!mounted) return;
      setState(() {
        _verseResults = results;
        _isLoading = false;
      });
    } else if (_searchType == _SearchType.interpretation) {
      final results = await InterpretationsDbHelper.searchInterpretationsByWord(
        q,
        isMalayalam: isMalayalam,
      );
      if (!mounted) return;
      setState(() {
        _interpretationResults = results;
        _isLoading = false;
      });
    } else {
      // Arabic text search — normalisation handled inside searchArabicVerses.
      final results = await TranslationBlockDbHelper.searchArabicVerses(
        q,
        isMalayalam: isMalayalam,
      );
      if (!mounted) return;
      setState(() {
        _arabicResults = results;
        _isLoading = false;
      });
    }
  }

  // ── navigation ────────────────────────────────────────────────────────────

  void _navigateTo(_NavTarget target) => Navigator.of(context).pop(target);

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final panelColor = isDark ? theme.cardColor : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black12;
    final primaryColor = isDark ? Colors.white : AppTheme.appThemePrimary;

    final screenSize = MediaQuery.sizeOf(context);
    final dialogHeight = (screenSize.height * 0.82).clamp(300.0, 700.0);
    const maxDialogWidth = 640.0;
    final hInset = screenSize.width < 640
        ? 12.0
        : ((screenSize.width - maxDialogWidth) / 2).clamp(
            24.0,
            double.infinity,
          );

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: hInset, vertical: 24),
      child: SizedBox(
        height: dialogHeight,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxDialogWidth),
          child: Container(
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(context, isMalayalam, primaryColor),
                const SizedBox(height: 10),
                _buildToggle(isMalayalam, primaryColor, isDark, panelColor),
                const SizedBox(height: 12),
                _buildSearchField(
                  isMalayalam,
                  primaryColor,
                  isDark,
                  borderColor,
                  theme,
                ),
                const SizedBox(height: 4),
                const Divider(height: 1),
                Expanded(
                  child: _buildResults(
                    isMalayalam,
                    primaryColor,
                    isDark,
                    theme,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    bool isMalayalam,
    Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
      child: Row(
        children: [
          Text(
            isMalayalam ? 'തിരയുക' : 'Search',
            style: TextStyle(
              color: primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => Navigator.of(context).pop(),
            color: primaryColor,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ── type toggle ───────────────────────────────────────────────────────────

  Widget _buildToggle(
    bool isMalayalam,
    Color primaryColor,
    bool isDark,
    Color panelColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _typeChip(
            label: isMalayalam ? 'പരിഭാഷ' : 'Translation',
            type: _SearchType.translation,
            primaryColor: primaryColor,
            isDark: isDark,
            isMalayalam: isMalayalam,
          ),
          _typeChip(
            label: isMalayalam ? 'വ്യാഖ്യാനം' : 'Interpretation',
            type: _SearchType.interpretation,
            primaryColor: primaryColor,
            isDark: isDark,
            isMalayalam: isMalayalam,
          ),
          _typeChip(
            label: isMalayalam ? 'അറബിക്' : 'Arabic',
            type: _SearchType.arabic,
            primaryColor: primaryColor,
            isDark: isDark,
            isMalayalam: isMalayalam,
          ),
        ],
      ),
    );
  }

  Widget _typeChip({
    required String label,
    required _SearchType type,
    required Color primaryColor,
    required bool isDark,
    required bool isMalayalam,
  }) {
    final selected = _searchType == type;
    return GestureDetector(
      onTap: () {
        if (_searchType == type) return;
        setState(() {
          _searchType = type;
          _verseResults = [];
          _interpretationResults = [];
          _arabicResults = [];
        });
        if (_controller.text.trim().length >= 2) {
          _onQueryChanged(_controller.text, isMalayalam);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? primaryColor
                : primaryColor.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? (isDark ? Colors.black87 : Colors.white)
                : primaryColor,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // ── search field ──────────────────────────────────────────────────────────

  Widget _buildSearchField(
    bool isMalayalam,
    Color primaryColor,
    bool isDark,
    Color borderColor,
    ThemeData theme,
  ) {
    final hint = _searchType == _SearchType.translation
        ? (isMalayalam ? 'പരിഭാഷ തിരയുക...' : 'Search in translation...')
        : _searchType == _SearchType.interpretation
        ? (isMalayalam ? 'വ്യാഖ്യാനം തിരയുക...' : 'Search in interpretation...')
        : (isMalayalam ? 'അറബിക് ആയത്ത് തിരയുക...' : 'Search Arabic text...');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _controller,
        autofocus: true,
        style: TextStyle(color: primaryColor, fontSize: 15),
        cursorColor: primaryColor,
        onChanged: (v) => _onQueryChanged(v, isMalayalam),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: primaryColor.withValues(alpha: 0.55),
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: primaryColor.withValues(alpha: 0.55),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      _verseResults = [];
                      _interpretationResults = [];
                      _arabicResults = [];
                      _isLoading = false;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.appThemePrimary.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppTheme.appThemePrimary.withValues(alpha: 0.55),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ── results area ──────────────────────────────────────────────────────────

  Widget _buildResults(
    bool isMalayalam,
    Color primaryColor,
    bool isDark,
    ThemeData theme,
  ) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final q = _controller.text.trim();
    if (q.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search,
                size: 44,
                color: primaryColor.withValues(alpha: 0.25),
              ),
              const SizedBox(height: 10),
              Text(
                isMalayalam ? 'തിരയാൻ ടൈപ്പ് ചെയ്യൂ' : 'Type to search',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_searchType == _SearchType.translation) {
      return _buildVerseResultList(isMalayalam, primaryColor, isDark, theme);
    } else if (_searchType == _SearchType.interpretation) {
      return _buildInterpretationResultList(
        isMalayalam,
        primaryColor,
        isDark,
        theme,
      );
    } else {
      return _buildArabicResultList(isMalayalam, primaryColor, isDark, theme);
    }
  }

  // ── count banner ──────────────────────────────────────────────────────────

  Widget _buildCountBanner(int count, bool isMalayalam, Color primaryColor) {
    final label = isMalayalam
        ? '$count ഫലങ്ങൾ'
        : '$count result${count == 1 ? '' : 's'}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Text(
        label,
        style: TextStyle(
          color: primaryColor.withValues(alpha: 0.55),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVerseResultList(
    bool isMalayalam,
    Color primaryColor,
    bool isDark,
    ThemeData theme,
  ) {
    if (_verseResults.isEmpty) {
      return _emptyState(isMalayalam, theme);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCountBanner(_verseResults.length, isMalayalam, primaryColor),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            itemCount: _verseResults.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final r = _verseResults[i];
              final surahName = _surahName(ctx, r.surahNumber);
              return _ResultTile(
                label: '$surahName (${r.surahNumber}:${r.verseNumber})',
                snippet: r.translationText,
                primaryColor: primaryColor,
                isDark: isDark,
                onTap: () => _navigateTo(
                  _NavTarget(
                    surahNumber: r.surahNumber,
                    verseNumber: r.verseNumber,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInterpretationResultList(
    bool isMalayalam,
    Color primaryColor,
    bool isDark,
    ThemeData theme,
  ) {
    if (_interpretationResults.isEmpty) {
      return _emptyState(isMalayalam, theme);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCountBanner(
          _interpretationResults.length,
          isMalayalam,
          primaryColor,
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            itemCount: _interpretationResults.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final r = _interpretationResults[i];
              final hasRef = r.surahNumber > 0 && r.verseNumber > 0;
              final surahName = r.surahNumber > 0
                  ? _surahName(ctx, r.surahNumber)
                  : '';
              final interpSuffix = isMalayalam
                  ? ' · വ്യാഖ്യാനം #${r.footnoteNumber}'
                  : ' · Interpretation #${r.footnoteNumber}';
              final label = hasRef
                  ? '$surahName (${r.surahNumber}:${r.verseNumber})$interpSuffix'
                  : r.surahNumber > 0
                  ? '$surahName$interpSuffix'
                  : (isMalayalam
                        ? 'വ്യാഖ്യാനം #${r.footnoteNumber}'
                        : 'Interpretation #${r.footnoteNumber}');
              return _ResultTile(
                label: label,
                snippet: r.text,
                primaryColor: primaryColor,
                isDark: isDark,
                onTap: hasRef
                    ? () => _navigateTo(
                        _NavTarget(
                          surahNumber: r.surahNumber,
                          verseNumber: r.verseNumber,
                        ),
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArabicResultList(
    bool isMalayalam,
    Color primaryColor,
    bool isDark,
    ThemeData theme,
  ) {
    if (_arabicResults.isEmpty) {
      return _emptyState(isMalayalam, theme);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCountBanner(_arabicResults.length, isMalayalam, primaryColor),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            itemCount: _arabicResults.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final r = _arabicResults[i];
              final surahName = _surahName(ctx, r.surahNumber);
              return InkWell(
                onTap: () => _navigateTo(
                  _NavTarget(
                    surahNumber: r.surahNumber,
                    verseNumber: r.verseNumber,
                  ),
                ),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$surahName (${r.surahNumber}:${r.verseNumber})',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          r.arabicText,
                          textAlign: TextAlign.right,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 17,
                            height: 1.7,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (r.translationText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          r.translationText.length > 160
                              ? '${r.translationText.substring(0, 160)}…'
                              : r.translationText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.6)
                                : Colors.black54,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _emptyState(bool isMalayalam, ThemeData theme) {
    return Center(
      child: Text(
        isMalayalam ? 'ഫലങ്ങൾ ലഭ്യമല്ല' : 'No results found',
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  String _surahName(BuildContext ctx, int surahNumber) {
    try {
      return ctx
          .read<SurahProvider>()
          .surahList
          .firstWhere((s) => s.surahNumber == surahNumber)
          .name;
    } catch (_) {
      return 'Surah $surahNumber';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result tile
// ─────────────────────────────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.label,
    required this.snippet,
    required this.primaryColor,
    required this.isDark,
    this.onTap,
  });

  final String label;
  final String snippet;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabledColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : Colors.black38;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: onTap != null ? primaryColor : disabledColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _truncated(snippet),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.75)
                    : Colors.black87,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _truncated(String text) {
    const max = 220;
    final t = text.trim();
    return t.length > max ? '${t.substring(0, max)}…' : t;
  }
}
