class TrainingRatingDetail {
  final int id;
  final int trainingId;
  final String trainingDate;
  final String trainingPlanName;
  final int rating;
  final String? comment;
  final double multiplier;
  final int userId;

  const TrainingRatingDetail({
    required this.id,
    required this.trainingId,
    required this.trainingDate,
    required this.trainingPlanName,
    required this.rating,
    this.comment,
    required this.multiplier,
    required this.userId,
  });

  factory TrainingRatingDetail.fromJson(Map<String, dynamic> json) {
    return TrainingRatingDetail(
      id: json['id'] as int,
      trainingId: json['training_id'] as int,
      trainingDate: json['training_date'] as String,
      trainingPlanName: json['training_plan_name'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      multiplier: (json['multiplier'] as num).toDouble(),
      userId: json['user_id'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'training_id': trainingId,
      'training_date': trainingDate,
      'training_plan_name': trainingPlanName,
      'rating': rating,
      'comment': comment,
      'multiplier': multiplier,
      'user_id': userId,
    };
  }

  TrainingRatingDetail copyWith({
    int? id,
    int? trainingId,
    String? trainingDate,
    String? trainingPlanName,
    int? rating,
    String? comment,
    double? multiplier,
    int? userId,
  }) {
    return TrainingRatingDetail(
      id: id ?? this.id,
      trainingId: trainingId ?? this.trainingId,
      trainingDate: trainingDate ?? this.trainingDate,
      trainingPlanName: trainingPlanName ?? this.trainingPlanName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      multiplier: multiplier ?? this.multiplier,
      userId: userId ?? this.userId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TrainingRatingDetail &&
        other.id == id &&
        other.trainingId == trainingId &&
        other.trainingDate == trainingDate &&
        other.trainingPlanName == trainingPlanName &&
        other.rating == rating &&
        other.comment == comment &&
        other.multiplier == multiplier &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        trainingId.hashCode ^
        trainingDate.hashCode ^
        trainingPlanName.hashCode ^
        rating.hashCode ^
        comment.hashCode ^
        multiplier.hashCode ^
        userId.hashCode;
  }

  @override
  String toString() {
    return 'TrainingRatingDetail{id: $id, trainingId: $trainingId, trainingDate: $trainingDate, trainingPlanName: $trainingPlanName, rating: $rating, comment: $comment, multiplier: $multiplier, userId: $userId}';
  }
}
