import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/core/utils/surah_place_localizer.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/last_read_provider.dart';
import 'package:the_message_of_the_quran/features/mushaf/widgets/star_number.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

Future<void> showSurahQuickSearchDialog(BuildContext context) async {
  final surahProvider = context.read<SurahProvider>();

  final selectedSurahNumber = await showDialog<int>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const SurahQuickSearchDialog(),
  );

  if (selectedSurahNumber == null || !context.mounted) {
    return;
  }

  final index = surahProvider.surahList.indexWhere(
    (surah) => surah.surahNumber == selectedSurahNumber,
  );
  if (index < 0) {
    return;
  }

  surahProvider.assignIndex(index);
  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const SurahScreen()));
  if (!context.mounted) {
    return;
  }
  context.read<LastReadProvider>().saveLastSurahTabSelection(
    selectedSurahNumber,
  );
}

class SurahQuickSearchDialog extends StatelessWidget {
  const SurahQuickSearchDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final surahProvider = context.watch<SurahProvider>();
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final width = MediaQuery.sizeOf(context).width;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: width < 640 ? 12 : 24,
        vertical: 24,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: viewInsets.bottom),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SurahQuickSearch(
                isMalayalam: isMalayalam,
                surahList: surahProvider.surahList,
                isLoading: surahProvider.isSurahLoading,
                autofocus: true,
                onSurahSelected: (surahNumber) {
                  Navigator.of(context).pop(surahNumber);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SurahQuickSearch extends StatefulWidget {
  const SurahQuickSearch({
    super.key,
    required this.isMalayalam,
    required this.surahList,
    required this.isLoading,
    required this.onSurahSelected,
    this.onSearchActiveChanged,
    this.autofocus = false,
    this.fieldMaxWidth = 560,
    this.resultsMaxWidth = 620,
  });

  final bool isMalayalam;
  final List<SurahModel> surahList;
  final bool isLoading;
  final ValueChanged<int> onSurahSelected;
  final ValueChanged<bool>? onSearchActiveChanged;
  final bool autofocus;
  final double fieldMaxWidth;
  final double resultsMaxWidth;

  @override
  State<SurahQuickSearch> createState() => _SurahQuickSearchState();
}

class _SurahQuickSearchState extends State<SurahQuickSearch> {
  static const double _fieldHeight = 48;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  bool get _isSearchActive => _normalizeQuery(_query).isNotEmpty;

  Color _primaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppTheme.appThemePrimary;
  }

  Color _secondaryText(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.grey[600]!;
  }

  Color _surfaceBorder(BuildContext context) {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.12)
        : (theme.dividerTheme.color ?? theme.colorScheme.outlineVariant);
  }

  bool _isDarkSurface(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  BoxDecoration _panelDecoration(BuildContext context, {double radius = 24}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: _isDarkSurface(context)
          ? null
          : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(255, 255, 255, 1),
                Color.fromRGBO(255, 250, 234, 1),
              ],
            ),
      color: _isDarkSurface(context) ? Theme.of(context).cardColor : null,
      border: Border.all(color: _surfaceBorder(context)),
    );
  }

  String _normalizeQuery(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _notifySearchActiveChanged(bool value) {
    widget.onSearchActiveChanged?.call(value);
  }

  void _handleQueryChanged(String value) {
    final wasSearchActive = _isSearchActive;
    setState(() {
      _query = value;
    });
    final isSearchActive = _isSearchActive;
    if (wasSearchActive != isSearchActive) {
      _notifySearchActiveChanged(isSearchActive);
    }
  }

  void _clearQuery() {
    final wasSearchActive = _isSearchActive;
    _controller.clear();
    _focusNode.unfocus();
    setState(() {
      _query = '';
    });
    if (wasSearchActive) {
      _notifySearchActiveChanged(false);
    }
  }

  void _selectSurah(int surahNumber) {
    _clearQuery();
    widget.onSurahSelected(surahNumber);
  }

  List<SurahModel> _searchResults() {
    final normalizedQuery = _normalizeQuery(_query);
    if (normalizedQuery.isEmpty) {
      return const <SurahModel>[];
    }

    return widget.surahList
        .where((surah) {
          final candidates = <String>[
            surah.surahNumber.toString(),
            surah.name,
            surah.searchName,
            surah.malayalamName,
            surah.description,
            surah.arabicName,
          ];

          return candidates.any(
            (candidate) => _normalizeQuery(candidate).contains(normalizedQuery),
          );
        })
        .toList(growable: false);
  }

  Widget _buildSearchField(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = _isDarkSurface(context);
    final surfaceColor = isDarkMode ? theme.cardColor : Colors.white;

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: _fieldHeight,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _surfaceBorder(context)),
          boxShadow: isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: AppTheme.appThemePrimary.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          onChanged: _handleQueryChanged,
          onTapOutside: (_) => _focusNode.unfocus(),
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          cursorColor: AppTheme.appThemePrimary,
          style: AppTextTheme.localizedBody(
            isMalayalam: widget.isMalayalam,
            fontSize: 14,
            color: _primaryText(context),
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: widget.isMalayalam
                ? 'സൂറത്തിന്റെ പേര് തിരയുക'
                : 'Search surah names',
            hintStyle: AppTextTheme.localizedBody(
              isMalayalam: widget.isMalayalam,
              fontSize: widget.isMalayalam ? 13 : 14,
              color: _secondaryText(context),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: _secondaryText(context),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: _fieldHeight,
            ),
            suffixIcon: _isSearchActive
                ? IconButton(
                    onPressed: _clearQuery,
                    splashRadius: 18,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: _secondaryText(context),
                    ),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: _fieldHeight,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildResultsPanel(BuildContext context) {
    final searchResults = _searchResults();

    return DecoratedBox(
      decoration: _panelDecoration(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.isMalayalam ? 'സൂറത്ത് റിസൾട്ടുകൾ' : 'Surah results',
                  style: AppTextTheme.localizedLabel(
                    isMalayalam: widget.isMalayalam,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _primaryText(context),
                  ),
                ),
                const Spacer(),
                Text(
                  '${searchResults.length} ${widget.isMalayalam ? 'പൊരുത്തങ്ങൾ' : 'matches'}',
                  style: AppTextTheme.localizedBody(
                    isMalayalam: widget.isMalayalam,
                    fontSize: 12,
                    color: _secondaryText(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (widget.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (searchResults.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  widget.isMalayalam
                      ? 'ഈ പേരിൽ ഒരു സൂറത്തും കണ്ടെത്താനായില്ല.'
                      : 'No surah name matched this search.',
                  style: AppTextTheme.localizedBody(
                    isMalayalam: widget.isMalayalam,
                    fontSize: 14,
                    color: _secondaryText(context),
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  primary: false,
                  shrinkWrap: true,
                  physics: searchResults.length > 4
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: searchResults.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _SurahQuickSearchResultCard(
                      isMalayalam: widget.isMalayalam,
                      surah: searchResults[index],
                      onTap: () {
                        _selectSurah(searchResults[index].surahNumber);
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: widget.fieldMaxWidth),
          child: _buildSearchField(context),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _isSearchActive
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: widget.resultsMaxWidth,
                    ),
                    child: _buildResultsPanel(context),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SurahQuickSearchResultCard extends StatelessWidget {
  const _SurahQuickSearchResultCard({
    required this.isMalayalam,
    required this.surah,
    required this.onTap,
  });

  final bool isMalayalam;
  final SurahModel surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final surfaceColor = isDarkMode
        ? theme.scaffoldBackgroundColor
        : Colors.white;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.10)
        : (theme.dividerTheme.color ?? theme.colorScheme.outlineVariant);
    final primaryTextColor = isDarkMode
        ? Colors.white
        : AppTheme.appThemePrimary;
    final secondaryTextColor = isDarkMode ? Colors.white70 : Colors.grey[600]!;
    final displayText = formatSurahListDisplayText(
      isMalayalam: isMalayalam,
      surahName: surah.name,
      surahTranslation: surah.description,
      malayalamName: surah.malayalamName,
      surahNumber: surah.surahNumber,
    );

    return Material(
      color: surfaceColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              StarNumber(number: surah.surahNumber, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayText.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextTheme.localizedLabel(
                        isMalayalam: isMalayalam,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      localizeSurahPlace(
                        surah.place,
                        isMalayalam: isMalayalam,
                        preferBareUncertain: true,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextTheme.localizedBody(
                        isMalayalam: isMalayalam,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                formatAyahCountLabel(
                  surah.ayathCount,
                  isMalayalam: isMalayalam,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppTextTheme.localizedBody(
                  isMalayalam: isMalayalam,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
