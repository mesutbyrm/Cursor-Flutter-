import 'package:equatable/equatable.dart';

enum PfTellerStatus { online, offline, busy }

class PfFortuneTeller extends Equatable {
  const PfFortuneTeller({
    required this.id,
    required this.name,
    required this.bio,
    required this.specialties,
    required this.rating,
    required this.reviewCount,
    required this.pricePerMinute,
    required this.status,
    this.photoUrl,
    this.isVerified = false,
  });

  final String id;
  final String name;
  final String bio;
  final List<String> specialties;
  final double rating;
  final int reviewCount;
  final int pricePerMinute;
  final PfTellerStatus status;
  final String? photoUrl;
  final bool isVerified;

  @override
  List<Object?> get props => [
        id,
        name,
        bio,
        specialties,
        rating,
        reviewCount,
        pricePerMinute,
        status,
        photoUrl,
        isVerified,
      ];
}

class PfAppointment extends Equatable {
  const PfAppointment({
    required this.id,
    required this.tellerId,
    required this.userId,
    required this.scheduledAt,
    required this.durationMinutes,
    this.notes,
  });

  final String id;
  final String tellerId;
  final String userId;
  final DateTime scheduledAt;
  final int durationMinutes;
  final String? notes;

  @override
  List<Object?> get props => [id, tellerId, userId, scheduledAt, durationMinutes, notes];
}
