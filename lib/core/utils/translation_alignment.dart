import 'package:flutter/material.dart';

TextAlign resolveTranslationTextAlign({
  required bool isMalayalam,
  required bool justifyTranslation,
}) {
  if (isMalayalam || !justifyTranslation) {
    return TextAlign.start;
  }

  return TextAlign.justify;
}
