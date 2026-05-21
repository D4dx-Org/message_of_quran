enum SurahPlaceKind { makkah, madinah }

SurahPlaceKind? resolveSurahPlaceKind(String place) {
  final normalized = place.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }

  if (normalized.contains('makk') ||
      normalized.contains('mecca') ||
      normalized.contains('مكي') ||
      normalized.contains('مكية') ||
      normalized.contains('മക്ക')) {
    return SurahPlaceKind.makkah;
  }

  if (normalized.contains('madin') ||
      normalized.contains('medina') ||
      normalized.contains('مدني') ||
      normalized.contains('مدنية') ||
      normalized.contains('മദീന')) {
    return SurahPlaceKind.madinah;
  }

  return null;
}

String localizeSurahPlace(String place, {required bool isMalayalam}) {
  switch (resolveSurahPlaceKind(place)) {
    case SurahPlaceKind.makkah:
      return isMalayalam ? 'മക്ക' : 'Makkah';
    case SurahPlaceKind.madinah:
      return isMalayalam ? 'മദീന' : 'Madinah';
    case null:
      return place.trim();
  }
}

String localizeSurahPeriodLabel(String place, {required bool isMalayalam}) {
  if (isMalayalam && resolveSurahPlaceKind(place) == SurahPlaceKind.madinah) {
    return 'മദീനാ കാലഘട്ടം';
  }

  final localizedPlace = localizeSurahPlace(place, isMalayalam: isMalayalam);
  if (localizedPlace.isEmpty) {
    return isMalayalam ? 'കാലഘട്ടം' : 'Period';
  }

  return isMalayalam ? '$localizedPlace കാലഘട്ടം' : '$localizedPlace Period';
}

String localizeSurahMadinahDisplayLabel(
  String place, {
  required bool isMalayalam,
  required int surahNumber,
  required String fallback,
}) {
  if (!isMalayalam || surahNumber == 2) {
    return fallback;
  }

  return resolveSurahPlaceKind(place) == SurahPlaceKind.madinah
      ? localizeSurahPeriodLabel(place, isMalayalam: true)
      : fallback;
}
