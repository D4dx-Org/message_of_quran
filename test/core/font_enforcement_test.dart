import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path/path.dart' as p;
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('AppTextTheme localized helpers map English and Malayalam to approved fonts', () {
    final englishFamilyBase = AppTextTheme.englishFontFamily.split('_').first;
    final malayalamFamilyBase = AppTextTheme.malayalamFontFamily.split('_').first;
    final englishBody = AppTextTheme.localizedBody(
      isMalayalam: false,
      fontSize: 14,
    );
    final englishLabel = AppTextTheme.localizedLabel(
      isMalayalam: false,
      fontSize: 13,
    );
    final malayalamBody = AppTextTheme.localizedBody(
      isMalayalam: true,
      fontSize: 14,
    );
    final malayalamTitle = AppTextTheme.localizedTitle(isMalayalam: true);

    expect(
      AppTextTheme.localizedFontFamily(isMalayalam: false),
      AppTextTheme.englishFontFamily,
    );
    expect(
      AppTextTheme.localizedFontFamily(isMalayalam: true),
      AppTextTheme.malayalamFontFamily,
    );
    expect(englishBody.fontFamily, startsWith(englishFamilyBase));
    expect(englishLabel.fontFamily, startsWith(englishFamilyBase));
    expect(malayalamBody.fontFamily, startsWith(malayalamFamilyBase));
    expect(malayalamTitle.fontFamily, startsWith(malayalamFamilyBase));
  });

  test('GoogleFonts is only used through AppTextTheme', () {
    final violations = _collectLibViolations(
      predicate: (relativePath, line) {
        if (relativePath == 'lib/core/theme/app_text_theme.dart') {
          return false;
        }
        return line.contains('GoogleFonts.');
      },
    );

    expect(
      violations,
      isEmpty,
      reason: 'GoogleFonts must only be used through AppTextTheme; direct usage is not permitted.\n${violations.join('\n')}',
    );
  });

  test('Only approved explicit fontFamily assignments exist in lib', () {
    // Arabic and Quranic fonts remain explicit exceptions to the UI font rule.
    const allowedFontFamilyFragments = [
      "fontFamily: 'Amiri'",
      "fontFamily: 'Uthmani'",
      "fontFamily: 'sura_names'",
      "fontFamily: 'QCF_BSML'",
      "fontFamily: hasGlyph ? 'QCF_BSML' : null",
      'fontFamily: controller.fontType',
      'fontFamily: _bsmlFontFamily',
      'fontFamily: _pageFontFamily',
      'fontFamily: fontFamily',
      'fontFamily: AppTextTheme.englishFontFamily',
      'fontFamily: AppTextTheme.malayalamFontFamily',
      'fontFamily: AppTextTheme.localizedFontFamily',
    ];

    final violations = _collectLibViolations(
      predicate: (_, line) {
        if (!line.contains('fontFamily:')) {
          return false;
        }
        return !allowedFontFamilyFragments.any(line.contains);
      },
    );

    expect(
      violations,
      isEmpty,
      reason: 'Hardcoded fontFamily violates theme enforcement; use AppTextTheme for English/Malayalam text and keep explicit Arabic/Quran exceptions only.\n${violations.join('\n')}',
    );
  });

  test('Legacy Malayalam-only helpers stay inside AppTextTheme', () {
    const disallowedHelperUsages = [
      'AppTextTheme.subTitleblack',
      'AppTextTheme.headingMalayalam',
      'AppTextTheme.surahHeadingMalayalam',
      'AppTextTheme.subTitleblackScaled',
      'AppTextTheme.headingMalayalamScaled',
      'AppTextTheme.surahHeadingMalayalamScaled',
    ];

    final violations = _collectLibViolations(
      predicate: (relativePath, line) {
        if (relativePath == 'lib/core/theme/app_text_theme.dart') {
          return false;
        }
        return disallowedHelperUsages.any(line.contains);
      },
    );

    expect(
      violations,
      isEmpty,
      reason: 'Legacy Malayalam-only helpers should not be used outside AppTextTheme; use localizedTitle, localizedBody, or localizedLabel instead.\n${violations.join('\n')}',
    );
  });
}

List<File> _listLibDartFiles() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList()
    ..sort((left, right) => left.path.compareTo(right.path));
  return files;
}

List<String> _collectLibViolations({
  required bool Function(String relativePath, String line) predicate,
}) {
  final violations = <String>[];

  for (final file in _listLibDartFiles()) {
    final relativePath = _formatRelativePath(file.path);
    var inBlockComment = false;
    final lines = file.readAsLinesSync();

    for (var index = 0; index < lines.length; index++) {
      final stripped = _stripDartComments(
        lines[index],
        inBlockComment: inBlockComment,
      );
      inBlockComment = stripped.inBlockComment;
      final line = stripped.line.trim();

      if (line.isEmpty) {
        continue;
      }
      if (!predicate(relativePath, line)) {
        continue;
      }

      violations.add('$relativePath:${index + 1} -> $line');
    }
  }

  return violations;
}

String _formatRelativePath(String filePath) {
  return p.relative(filePath, from: Directory.current.path).replaceAll('\\', '/');
}

_CommentStripResult _stripDartComments(
  String line, {
  required bool inBlockComment,
}) {
  final buffer = StringBuffer();
  var index = 0;
  var insideBlockComment = inBlockComment;

  while (index < line.length) {
    if (insideBlockComment) {
      final endIndex = line.indexOf('*/', index);
      if (endIndex == -1) {
        return const _CommentStripResult('', inBlockComment: true);
      }
      insideBlockComment = false;
      index = endIndex + 2;
      continue;
    }

    final lineCommentIndex = line.indexOf('//', index);
    final blockCommentIndex = line.indexOf('/*', index);

    if (lineCommentIndex != -1 &&
        (blockCommentIndex == -1 || lineCommentIndex < blockCommentIndex)) {
      buffer.write(line.substring(index, lineCommentIndex));
      break;
    }

    if (blockCommentIndex != -1) {
      buffer.write(line.substring(index, blockCommentIndex));
      insideBlockComment = true;
      index = blockCommentIndex + 2;
      continue;
    }

    buffer.write(line.substring(index));
    break;
  }

  return _CommentStripResult(
    buffer.toString(),
    inBlockComment: insideBlockComment,
  );
}

class _CommentStripResult {
  const _CommentStripResult(this.line, {required this.inBlockComment});

  final String line;
  final bool inBlockComment;
}