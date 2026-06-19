import 'package:equatable/equatable.dart';

/// Falcı değerlendirmesi — `GET /api/fortune-tellers/{id}/reviews`.
class PsychicReviewEntity extends Equatable {
  const PsychicReviewEntity({
    required this.id,
    required this.rating,
    this.comment,
    this.clientName,
    this.fortuneType,
    this.createdAt,
  });

  final String id;
  final int rating;
  final String? comment;
  final String? clientName;
  final String? fortuneType;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, rating, comment, clientName, fortuneType, createdAt];
}
