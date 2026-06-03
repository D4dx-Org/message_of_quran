import 'package:flutter/material.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';

const homeListTopPadding = 0.0;
const homeListRowPadding = EdgeInsets.symmetric(vertical: 8, horizontal: 4);
const homeListBadgeSize = 42.0;
const homeListLeadingGap = 14.0;
const homeListTrailingGap = 12.0;
const homeListEndGap = 8.0;
const homeListRowBottomGap = 6.0;

TextStyle homeListPrimaryTextStyle({
  required bool isMalayalam,
  required Color color,
  required double scale,
}) {
  return AppTextTheme.localizedLabel(
    isMalayalam: isMalayalam,
    color: color,
    fontWeight: FontWeight.w600,
    fontSize: 14 * scale,
  );
}

TextStyle homeListSubtitleTextStyle({
  required bool isMalayalam,
  required Color color,
  required double scale,
}) {
  return AppTextTheme.localizedBody(
    isMalayalam: isMalayalam,
    fontSize: 11 * scale,
    color: color,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );
}

TextStyle homeListPlaceTextStyle({
  required bool isMalayalam,
  required Color color,
  required double scale,
}) {
  return AppTextTheme.localizedLabel(
    isMalayalam: isMalayalam,
    color: color,
    fontSize: 11 * scale,
    fontWeight: FontWeight.w600,
  );
}

TextStyle homeListAyahMetaTextStyle({
  required bool isMalayalam,
  required Color color,
  required double scale,
}) {
  return AppTextTheme.localizedLabel(
    isMalayalam: isMalayalam,
    fontSize: 10.5 * scale,
    color: color,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );
}