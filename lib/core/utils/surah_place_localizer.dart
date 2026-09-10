enum SurahPlaceKind { makkah, madinah }

/// Whether [place] is one of the various ways the source data marks a
/// surah's revelation period as unresolved, in either language. The
/// Malayalam data alone has five different phrasings for this -- e.g.
/// 'കാലഘട്ടം അവ്യക്തം', 'അവതരണകാലം നിർണിതമല്ല', 'കാലം നിർണിതമല്ല' -- so a
/// raw pass-through showed a different sentence on almost every uncertain
/// surah instead of one consistent label.
bool _isUncertainPeriod(String place) {
  final normalized = place.trim().toLowerCase();
  if (normalized.isEmpty) return false;
  return normalized.contains('uncertain') ||
      normalized.contains('അവ്യക്തം') ||
      normalized.contains('നിർണിത');
}

bool _isCompletePeriodPhrase(String place, {required bool isMalayalam}) {
  final normalized = place.trim().toLowerCase();
  if (normalized.isEmpty) {
    return false;
  }

  return isMalayalam
      ? normalized.contains('കാലഘട്ട')
      : normalized.contains('period');
}

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

String localizeSurahPlace(
  String place, {
  required bool isMalayalam,
  bool preferBareUncertain = false,
}) {
  switch (resolveSurahPlaceKind(place)) {
    case SurahPlaceKind.makkah:
      return isMalayalam ? 'മക്ക' : 'Makkah';
    case SurahPlaceKind.madinah:
      return isMalayalam ? 'മദീന' : 'Madinah';
    case null:
      if (_isUncertainPeriod(place)) {
        // One canonical phrase for every surah the source marks uncertain,
        // in place of whichever of the five Malayalam variants that
        // particular row happened to carry.
        return isMalayalam
            ? 'കാലഘട്ടം അവ്യക്തം'
            : (preferBareUncertain ? 'Uncertain' : 'Period Uncertain');
      }

      return place.trim();
  }
}

String localizeSurahPeriodLabel(String place, {required bool isMalayalam}) {
  if (_isCompletePeriodPhrase(place, isMalayalam: isMalayalam)) {
    return localizeSurahPlace(place, isMalayalam: isMalayalam);
  }

  if (isMalayalam && resolveSurahPlaceKind(place) == SurahPlaceKind.madinah) {
    return 'മദീനാ കാലഘട്ടം';
  }

  final localizedPlace = localizeSurahPlace(place, isMalayalam: isMalayalam);
  if (localizedPlace.isEmpty) {
    return isMalayalam ? 'കാലഘട്ടം' : 'Period';
  }

  if (_isCompletePeriodPhrase(localizedPlace, isMalayalam: isMalayalam)) {
    return localizedPlace;
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
