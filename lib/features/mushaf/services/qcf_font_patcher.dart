import 'dart:developer';
import 'dart:typed_data';

/// Patches a QCF V2 TTF font so that codepoint U+E07F aliases the glyph
/// that is mapped to U+007F.
///
/// Flutter suppresses U+007F (DEL control character) during text rendering,
/// which breaks pages that use this byte as a valid glyph selector in the QCF
/// V2 font. The patch rewrites the cmap table to add a mapping from U+E07F
/// to the same glyph-id as U+007F so Flutter can render it via the private-use
/// code-point instead.
///
/// This class is intentionally stateless. Call [patch] on raw font bytes and
/// it returns the patched bytes or the original bytes unchanged on any error.
class QcfFontPatcher {
  QcfFontPatcher._();

  static const int _e07f = 0xE07F;
  static const int _cp007f = 0x007F;

  /// Patches [fontBytes] and returns the modified byte array.
  ///
  /// If the font already contains an entry for U+E07F, or if patching fails
  /// for any reason, the original [fontBytes] are returned unchanged.
  static Uint8List patch(Uint8List fontBytes) {
    try {
      return _doPatch(fontBytes);
    } catch (e) {
      log('QcfFontPatcher: patch failed (returning original): $e');
      return fontBytes;
    }
  }

  static Uint8List _doPatch(Uint8List bytes) {
    final data = ByteData.sublistView(bytes);

    // Locate the cmap table
    final numTables = data.getUint16(4);
    int? cmapOffset;
    for (var i = 0; i < numTables; i++) {
      final tag = String.fromCharCodes(bytes.sublist(12 + i * 16, 12 + i * 16 + 4));
      if (tag == 'cmap') {
        cmapOffset = data.getUint32(12 + i * 16 + 8);
        break;
      }
    }
    if (cmapOffset == null) {
      log('QcfFontPatcher: no cmap table found');
      return bytes;
    }

    // Find a format-4 cmap sub-table
    final numSubTables = data.getUint16(cmapOffset + 2);
    int? fmt4Offset;
    for (var i = 0; i < numSubTables; i++) {
      final base = cmapOffset + 4 + i * 8;
      final platformId = data.getUint16(base);
      final encodingId = data.getUint16(base + 2);
      final subtableOffset = cmapOffset + data.getUint32(base + 4);
      final format = data.getUint16(subtableOffset);
      if (format == 4 && (platformId == 3 && encodingId == 1 || platformId == 0)) {
        fmt4Offset = subtableOffset;
        break;
      }
    }
    if (fmt4Offset == null) {
      log('QcfFontPatcher: no format-4 cmap sub-table found');
      return bytes;
    }

    // Read format-4 header
    final length = data.getUint16(fmt4Offset + 2);
    final segCount = data.getUint16(fmt4Offset + 6) ~/ 2;

    final endCodesBase = fmt4Offset + 14;
    final startCodesBase = fmt4Offset + 16 + segCount * 2;
    final idDeltaBase = fmt4Offset + 16 + segCount * 4;
    final idRangeOffsetBase = fmt4Offset + 16 + segCount * 6;
    final glyphIdArrayBase = fmt4Offset + 16 + segCount * 8;

    // Find the glyph id for U+007F
    int glyphIdFor007F = 0;
    for (var s = 0; s < segCount; s++) {
      final endCode = data.getUint16(endCodesBase + s * 2);
      if (_cp007f > endCode) continue;
      final startCode = data.getUint16(startCodesBase + s * 2);
      if (_cp007f < startCode) continue;

      final idRangeOffset = data.getUint16(idRangeOffsetBase + s * 2);
      if (idRangeOffset == 0) {
        final delta = data.getInt16(idDeltaBase + s * 2);
        glyphIdFor007F = (_cp007f + delta) & 0xFFFF;
      } else {
        final idx = idRangeOffset ~/ 2 + (_cp007f - startCode) + s;
        final glyphIdOffset = idRangeOffsetBase + idx * 2;
        if (glyphIdOffset + 2 > bytes.length) {
          log('QcfFontPatcher: glyph offset out of range');
          return bytes;
        }
        glyphIdFor007F = data.getUint16(glyphIdOffset);
        if (glyphIdFor007F != 0) {
          final delta = data.getInt16(idDeltaBase + s * 2);
          glyphIdFor007F = (glyphIdFor007F + delta) & 0xFFFF;
        }
      }
      break;
    }

    if (glyphIdFor007F == 0) {
      log('QcfFontPatcher: glyph for U+007F is 0/missing — skipping patch');
      return bytes;
    }

    // Check if U+E07F already mapped
    for (var s = 0; s < segCount; s++) {
      final endCode = data.getUint16(endCodesBase + s * 2);
      if (_e07f > endCode) continue;
      final startCode = data.getUint16(startCodesBase + s * 2);
      if (_e07f >= startCode) {
        log('QcfFontPatcher: U+E07F already mapped — no patch needed');
        return bytes;
      }
    }

    // Insert a new single-character segment for U+E07F before the 0xFFFF sentinel
    final int newSegCount = segCount + 1;

    final newEndCodes = Uint16List(newSegCount);
    final newStartCodes = Uint16List(newSegCount);
    final newIdDeltas = Int16List(newSegCount);

    final sentinelIdx = segCount - 1;
    for (var s = 0; s < sentinelIdx; s++) {
      newEndCodes[s] = data.getUint16(endCodesBase + s * 2);
      newStartCodes[s] = data.getUint16(startCodesBase + s * 2);
      newIdDeltas[s] = data.getInt16(idDeltaBase + s * 2);
    }

    // New segment for U+E07F
    newEndCodes[sentinelIdx] = _e07f;
    newStartCodes[sentinelIdx] = _e07f;
    newIdDeltas[sentinelIdx] = (glyphIdFor007F - _e07f) & 0xFFFF;

    // Restore the final 0xFFFF sentinel
    newEndCodes[newSegCount - 1] = 0xFFFF;
    newStartCodes[newSegCount - 1] = 0xFFFF;
    newIdDeltas[newSegCount - 1] = 1;

    final glyphIdArrayLen = bytes.length - glyphIdArrayBase;

    final newSubTableLen = 16 + newSegCount * 8 + (glyphIdArrayLen > 0 ? glyphIdArrayLen : 0);
    final newSubTable = ByteData(newSubTableLen);
    newSubTable.setUint16(0, 4); // format
    newSubTable.setUint16(2, newSubTableLen);
    newSubTable.setUint16(4, data.getUint16(fmt4Offset + 4)); // language
    newSubTable.setUint16(6, newSegCount * 2); // segCountX2
    final searchRange = _highestPowerOf2(newSegCount) * 2;
    newSubTable.setUint16(8, searchRange);
    newSubTable.setUint16(10, _log2(searchRange ~/ 2));
    newSubTable.setUint16(12, newSegCount * 2 - searchRange);

    const newEndBase = 14;
    final newStartBase = newEndBase + 2 + newSegCount * 2;
    final newDeltaBase = newStartBase + newSegCount * 2;
    final newRangeBase = newDeltaBase + newSegCount * 2;
    final newGlyphBase = newRangeBase + newSegCount * 2;

    newSubTable.setUint16(newEndBase + newSegCount * 2, 0); // reserved padding

    for (var s = 0; s < newSegCount; s++) {
      newSubTable.setUint16(newEndBase + s * 2, newEndCodes[s]);
      newSubTable.setUint16(newStartBase + s * 2, newStartCodes[s]);
      newSubTable.setInt16(newDeltaBase + s * 2, newIdDeltas[s]);
      newSubTable.setUint16(newRangeBase + s * 2, 0);
    }

    if (glyphIdArrayLen > 0) {
      final existingGlyphs = bytes.sublist(glyphIdArrayBase);
      final glyphView = Uint8List.view(newSubTable.buffer, newGlyphBase);
      glyphView.setAll(0, existingGlyphs.take(glyphView.length));
    }

    // Rebuild the full font bytes with the new sub-table
    final newFontLength = bytes.length - length + newSubTableLen;
    final newFont = Uint8List(newFontLength);
    newFont.setAll(0, bytes.sublist(0, fmt4Offset));
    newFont.setAll(fmt4Offset, Uint8List.view(newSubTable.buffer, 0, newSubTableLen));
    newFont.setAll(fmt4Offset + newSubTableLen, bytes.sublist(fmt4Offset + length));

    final bd = ByteData.sublistView(newFont);
    bd.setUint16(fmt4Offset + 2, newSubTableLen);

    _updateTableChecksum(newFont, cmapOffset, newSubTableLen + (fmt4Offset - cmapOffset));

    log('QcfFontPatcher: patched U+E07F → glyph $glyphIdFor007F');
    return newFont;
  }

  static int _highestPowerOf2(int n) {
    var p = 1;
    while (p * 2 <= n) {
      p *= 2;
    }
    return p;
  }

  static int _log2(int n) {
    var l = 0;
    while (n > 1) {
      n >>= 1;
      l++;
    }
    return l;
  }

  static void _updateTableChecksum(Uint8List font, int tableOffset, int tableLength) {
    var checksum = 0;
    for (var i = 0; i < tableLength; i += 4) {
      if (tableOffset + i + 3 < font.length) {
        final bd = ByteData.sublistView(font, tableOffset + i, tableOffset + i + 4);
        checksum = (checksum + bd.getUint32(0)) & 0xFFFFFFFF;
      }
    }
    final numTables = ByteData.sublistView(font).getUint16(4);
    for (var i = 0; i < numTables; i++) {
      final base = 12 + i * 16;
      final tag = String.fromCharCodes(font.sublist(base, base + 4));
      if (tag == 'cmap') {
        ByteData.sublistView(font).setUint32(base + 4, checksum);
        break;
      }
    }
  }
}
