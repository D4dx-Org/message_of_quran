class TranslatorNoteModel {
  final int? id;
  final String? heading;
  final String? content;
  final String? author;
  final String? date;

  TranslatorNoteModel({
    this.id,
    this.heading,
    this.content,
    this.author,
    this.date,
  });

  factory TranslatorNoteModel.fromJson(Map<String, dynamic> json) {
    return TranslatorNoteModel(
      id: json['id'],
      heading: json['heading'],
      content: json['content'],
      author: json['author'],
      date: json['date'],
    );
  }
}
