import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:the_message_of_the_quran/core/utils/translation_alignment.dart';

void main() {
  group('resolveTranslationTextAlign', () {
    test(
      'keeps Malayalam translations left aligned when justify is enabled',
      () {
        expect(
          resolveTranslationTextAlign(
            isMalayalam: true,
            justifyTranslation: true,
          ),
          TextAlign.start,
        );
      },
    );

    test(
      'keeps Malayalam translations left aligned when justify is disabled',
      () {
        expect(
          resolveTranslationTextAlign(
            isMalayalam: true,
            justifyTranslation: false,
          ),
          TextAlign.start,
        );
      },
    );

    test('keeps English translations justified when justify is enabled', () {
      expect(
        resolveTranslationTextAlign(
          isMalayalam: false,
          justifyTranslation: true,
        ),
        TextAlign.justify,
      );
    });

    test(
      'keeps English translations left aligned when justify is disabled',
      () {
        expect(
          resolveTranslationTextAlign(
            isMalayalam: false,
            justifyTranslation: false,
          ),
          TextAlign.start,
        );
      },
    );
  });

  group('resolveInterpretationTextAlign', () {
    test(
      'keeps Malayalam interpretations left aligned when justify is enabled',
      () {
        expect(
          resolveInterpretationTextAlign(
            isMalayalam: true,
            justifyInterpretation: true,
          ),
          TextAlign.start,
        );
      },
    );

    test(
      'keeps Malayalam interpretations left aligned when justify is disabled',
      () {
        expect(
          resolveInterpretationTextAlign(
            isMalayalam: true,
            justifyInterpretation: false,
          ),
          TextAlign.start,
        );
      },
    );

    test('keeps English interpretations justified when justify is enabled', () {
      expect(
        resolveInterpretationTextAlign(
          isMalayalam: false,
          justifyInterpretation: true,
        ),
        TextAlign.justify,
      );
    });

    test(
      'keeps English interpretations left aligned when justify is disabled',
      () {
        expect(
          resolveInterpretationTextAlign(
            isMalayalam: false,
            justifyInterpretation: false,
          ),
          TextAlign.start,
        );
      },
    );
  });
}
