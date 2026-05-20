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

String _specialMalayalamSurahSubtitle(int surahNumber) {
  switch (surahNumber) {
    case 1:
      return 'പ്രാരംഭം';
    case 2:
      return 'പശു';
    default:
      return '';
  }
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

  return SurahListDisplayText(
    title: _baseMalayalamSurahName(
      surahName: surahName,
      malayalamName: malayalamName,
    ),
    subtitle: _specialMalayalamSurahSubtitle(surahNumber),
  );
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
