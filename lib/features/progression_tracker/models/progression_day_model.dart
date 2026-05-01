class ProgressionDayModel {
  final int? id;
  final int progressionId;
  final int dayNumber;
  final int startAyah;
  final int endAyah;
  final String status; // pending, reading, completed

  ProgressionDayModel({
    this.id,
    required this.progressionId,
    required this.dayNumber,
    required this.startAyah,
    required this.endAyah,
    this.status = 'pending',
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'progression_id': progressionId,
      'day_number': dayNumber,
      'start_ayah': startAyah,
      'end_ayah': endAyah,
      'status': status,
    };
  }

  factory ProgressionDayModel.fromMap(Map<String, dynamic> map) {
    return ProgressionDayModel(
      id: map['id'] as int?,
      progressionId: map['progression_id'] as int,
      dayNumber: map['day_number'] as int,
      startAyah: map['start_ayah'] as int,
      endAyah: map['end_ayah'] as int,
      status: map['status'] as String? ?? 'pending',
    );
  }

  ProgressionDayModel copyWith({String? status}) {
    return ProgressionDayModel(
      id: id,
      progressionId: progressionId,
      dayNumber: dayNumber,
      startAyah: startAyah,
      endAyah: endAyah,
      status: status ?? this.status,
    );
  }
}
