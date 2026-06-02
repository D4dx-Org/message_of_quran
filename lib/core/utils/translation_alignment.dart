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

TextAlign resolveInterpretationTextAlign({
  required bool isMalayalam,
  required bool justifyInterpretation,
}) {
  if (isMalayalam || !justifyInterpretation) {
    return TextAlign.start;
  }

  return TextAlign.justify;
}
