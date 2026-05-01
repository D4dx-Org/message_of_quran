/// Represents a single line (or heading/bismillah) from the `t_mushafpages`
/// table.  Each row maps to one visual line on a Mushaf page.
class MushafLine {
  const MushafLine({
    required this.pageId,
    required this.suraId,
    required this.lineId,
    required this.data,
  });

  /// Page number (1-604).
  final int pageId;

  /// Sura that this line belongs to.
  final int suraId;

  /// Line type:
  /// * `-1` → Sura heading (rendered with QCF_BSML)
  /// *  `0` → Bismillah line (rendered with QCF_BSML)
  /// * `1+` → Aya text line (rendered with the page font QCF_P{NNN})
  final int lineId;

  /// Raw glyph data stored in reversed order. Use [MushafTextUtils.reverseText]
  /// before rendering.  Contains special delimiters:
  /// * `▌` — aya boundary within the same line
  /// * `▼` — aya continues on the next line
  final String data;

  factory MushafLine.fromMap(Map<String, Object?> map) {
    return MushafLine(
      pageId: (map['pageid'] as num).toInt(),
      suraId: (map['suraid'] as num).toInt(),
      lineId: (map['line'] as num).toInt(),
      data: (map['data'] as String?) ?? '',
    );
  }
}
