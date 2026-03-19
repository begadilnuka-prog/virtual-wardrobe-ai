class PlannedOutfit {
  const PlannedOutfit({
    required this.userId,
    required this.dayIndex,
    required this.outfitId,
    required this.updatedAt,
  });

  final String userId;
  final int dayIndex;
  final String outfitId;
  final DateTime updatedAt;

  PlannedOutfit copyWith({
    String? userId,
    int? dayIndex,
    String? outfitId,
    DateTime? updatedAt,
  }) {
    return PlannedOutfit(
      userId: userId ?? this.userId,
      dayIndex: dayIndex ?? this.dayIndex,
      outfitId: outfitId ?? this.outfitId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'dayIndex': dayIndex,
      'outfitId': outfitId,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PlannedOutfit.fromMap(Map<String, dynamic> map) {
    return PlannedOutfit(
      userId: map['userId'] as String,
      dayIndex: map['dayIndex'] as int? ?? 0,
      outfitId: map['outfitId'] as String? ?? '',
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
