/// Metadata for one Mushaf page, loaded from `t_ayawise_page`.
class PageMeta {
  const PageMeta({
    required this.pageNo,
    required this.suraNo,
    required this.startAya,
    required this.endAya,
    required this.juzNo,
    required this.hizbNo,
  });

  final int pageNo;
  final int suraNo;
  final int startAya;
  final int endAya;
  final int juzNo;
  final int hizbNo;

  factory PageMeta.fromMap(Map<String, Object?> map) {
    return PageMeta(
      pageNo: (map['p_id'] as num).toInt(),
      suraNo: (map['s_no'] as num).toInt(),
      startAya: (map['s_aya'] as num).toInt(),
      endAya: (map['e_aya'] as num).toInt(),
      juzNo: (map['j_no'] as num).toInt(),
      hizbNo: (map['Hizb_no'] as num?)?.toInt() ?? 0,
    );
  }
}
