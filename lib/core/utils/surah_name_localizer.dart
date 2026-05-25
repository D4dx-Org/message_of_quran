String _surahNameLine(String surahName, String surahTranslation) {
  final trimmedTranslation = surahTranslation.trim();
  if (trimmedTranslation.isEmpty) {
    return surahName;
  }
  return '$surahName ($trimmedTranslation)';
}

class SurahListDisplayText {
  const SurahListDisplayText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

String formatAyahCountLabel(int ayahCount, {required bool isMalayalam}) {
  return isMalayalam ? '$ayahCount ആയത്ത്' : '$ayahCount Ayahs';
}

String formatAyahReferenceLabel(int ayahNumber, {required bool isMalayalam}) {
  return isMalayalam ? 'ആയത്ത് $ayahNumber' : 'Ayah $ayahNumber';
}

String formatAyahRangeLabel(int start, int end, {required bool isMalayalam}) {
  return isMalayalam ? 'ആയത്തുകൾ $start – $end' : 'Ayahs $start – $end';
}

String formatAyatulKursiLabel({required bool isMalayalam}) {
  return isMalayalam ? 'ആയത്തുൽ കുർസി' : 'Ayatul Kursi';
}

String _baseMalayalamSurahName({
  required String surahName,
  required String malayalamName,
}) {
  final trimmedMalayalamName = malayalamName.trim();
  return trimmedMalayalamName.isNotEmpty ? trimmedMalayalamName : surahName;
}

SurahListDisplayText _parseMalayalamDisplayText(String malayalamName) {
  final openParen = malayalamName.indexOf('(');
  final closeParen = malayalamName.lastIndexOf(')');
  if (openParen > 0 && closeParen > openParen) {
    final title = malayalamName.substring(0, openParen).trim();
    final subtitle = malayalamName.substring(openParen + 1, closeParen).trim();
    return SurahListDisplayText(title: title, subtitle: subtitle);
  }
  return SurahListDisplayText(title: malayalamName, subtitle: '');
}

SurahListDisplayText formatSurahListDisplayText({
  required bool isMalayalam,
  required String surahName,
  required String surahTranslation,
  required String malayalamName,
  required int surahNumber,
}) {
  if (!isMalayalam) {
    return SurahListDisplayText(
      title: surahName,
      subtitle: surahTranslation.trim(),
    );
  }

  final baseName = _baseMalayalamSurahName(
    surahName: surahName,
    malayalamName: malayalamName,
  );
  return _parseMalayalamDisplayText(baseName);
}

String formatSurahDisplayNameLine({
  required bool isMalayalam,
  required String surahName,
  required String surahTranslation,
  required String malayalamName,
  required int surahNumber,
}) {
  if (!isMalayalam) {
    return _surahNameLine(surahName, surahTranslation);
  }

  final displayText = formatSurahListDisplayText(
    isMalayalam: true,
    surahName: surahName,
    surahTranslation: surahTranslation,
    malayalamName: malayalamName,
    surahNumber: surahNumber,
  );
  if (displayText.subtitle.isEmpty) {
    return displayText.title;
  }

  return '${displayText.title} (${displayText.subtitle})';
}
