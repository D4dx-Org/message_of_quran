class ProgressionAyahModel {
  final int? id;
  final int progressionId;
  final int dayId;
  final int ayahNumber;
  final String status; // locked, pending, reading, completed

  ProgressionAyahModel({
    this.id,
    required this.progressionId,
    required this.dayId,
    required this.ayahNumber,
    this.status = 'locked',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'progression_id': progressionId,
      'day_id': dayId,
      'ayah_number': ayahNumber,
      'status': status,
    };
  }

  factory ProgressionAyahModel.fromMap(Map<String, dynamic> map) {
    return ProgressionAyahModel(
      id: map['id'] as int?,
      progressionId: map['progression_id'] as int,
      dayId: map['day_id'] as int,
      ayahNumber: map['ayah_number'] as int,
      status: map['status'] as String? ?? 'locked',
    );
  }

  ProgressionAyahModel copyWith({String? status}) {
    return ProgressionAyahModel(
      id: id,
      progressionId: progressionId,
      dayId: dayId,
      ayahNumber: ayahNumber,
      status: status ?? this.status,
    );
  }
}
