import 'package:equatable/equatable.dart';

/// Falcı ödülü — `GET /api/fortune-tellers/awards?tellerId=`.
class PsychicAwardEntity extends Equatable {
  const PsychicAwardEntity({
    required this.id,
    required this.tellerId,
    required this.awardType,
    required this.title,
    this.startDate,
    this.endDate,
    this.createdAt,
  });

  final String id;
  final String tellerId;
  final String awardType;
  final String title;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, tellerId, awardType, title, startDate, endDate, createdAt];
}
