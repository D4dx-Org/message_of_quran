import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/surah_model.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/core/widgets/link_hover/hover_link.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class SurahChipRow extends StatelessWidget {
  const SurahChipRow({super.key, this.useCompactWebLayout});

  static const double _webChipPadding = 6;
  static const double _webChipGap = 6;
  static const double _webRowHorizontalPadding = 12;

  final bool? useCompactWebLayout;

  static const List<({int surahNumber, int? ayahId})> chips = [
    (surahNumber: 2, ayahId: 255),
    (surahNumber: 36, ayahId: null),
    (surahNumber: 67, ayahId: null),
    (surahNumber: 55, ayahId: null),
    (surahNumber: 56, ayahId: null),
    (surahNumber: 18, ayahId: null),
  ];

  static String _chipLabel({
    required bool isMalayalam,
    required List<SurahModel> surahList,
    required int surahNumber,
    int? ayahId,
  }) {
    if (ayahId == 255) return formatAyatulKursiLabel(isMalayalam: isMalayalam);

    final surah = surahList
        .where((s) => s.surahNumber == surahNumber)
        .firstOrNull;
    if (surah == null) return 'Surah $surahNumber';

    return formatSurahListDisplayText(
      isMalayalam: isMalayalam,
      surahName: surah.name,
      surahTranslation: surah.description,
      malayalamName: surah.malayalamName,
      surahNumber: surah.surahNumber,
    ).title;
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final surahList = context.watch<SurahProvider>().surahList;
    final shouldUseCompactWebLayout = useCompactWebLayout ?? kIsWeb;

    if (shouldUseCompactWebLayout) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: _webRowHorizontalPadding,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(chips.length, (index) {
            final chip = chips[index];
            final label = _chipLabel(
              isMalayalam: isMalayalam,
              surahList: surahList,
              surahNumber: chip.surahNumber,
              ayahId: chip.ayahId,
            );

            return Padding(
              padding: EdgeInsets.only(
                right: index == chips.length - 1 ? 0 : _webChipGap,
              ),
              child: _SurahChip(
                label: label,
                isMalayalam: isMalayalam,
                ayahId: chip.ayahId,
                surahNumber: chip.surahNumber,
                compact: true,
                compactPadding: _webChipPadding,
              ),
            );
          }),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final chip = chips[index];
          final label = _chipLabel(
            isMalayalam: isMalayalam,
            surahList: surahList,
            surahNumber: chip.surahNumber,
            ayahId: chip.ayahId,
          );

          return _SurahChip(
            label: label,
            isMalayalam: isMalayalam,
            ayahId: chip.ayahId,
            surahNumber: chip.surahNumber,
            compact: false,
          );
        },
      ),
    );
  }
}

class _SurahChip extends StatelessWidget {
  const _SurahChip({
    required this.label,
    required this.isMalayalam,
    required this.surahNumber,
    required this.compact,
    this.compactPadding = 12,
    this.ayahId,
  });

  final String label;
  final bool isMalayalam;
  final int surahNumber;
  final int? ayahId;
  final bool compact;
  final double compactPadding;

  @override
  Widget build(BuildContext context) {
    final url =
        '/surah/$surahNumber${ayahId != null ? '?scrollToAyahId=$ayahId' : ''}';
    return HoverLink(
      url: url,
      child: GestureDetector(
        onTap: () {
          // Open the surah EXACTLY like the other chips (Yaseen,
          // Al Mulk, etc.) — push immediately. SurahScreen loads its data
          // and, when scrollToAyahId is non-null (e.g. Ayatul Kursi = 255),
          // automatically scrolls to that ayah once the layout is ready.
          context.push(url);
        },
        child: Container(
          padding: compact
              ? EdgeInsets.all(compactPadding)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.appThemeRawChips,
            borderRadius: BorderRadius.circular(compact ? 16 : 20),
          ),
          alignment: compact ? null : Alignment.center,
          child: Text(
            label,
            style: AppTextTheme.localizedLabel(
              isMalayalam: isMalayalam,
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
