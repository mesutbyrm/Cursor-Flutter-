import 'package:equatable/equatable.dart';

/// Canlı falcı profili — `GET /api/fortune-tellers`.
class PsychicEntity extends Equatable {
  const PsychicEntity({
    required this.id,
    required this.name,
    this.userId,
    this.bio,
    this.avatarUrl,
    this.isOnline = false,
    this.rating = 0,
    this.reviewCount = 0,
    this.pricePerMinute = 0,
    this.specialties = const [],
    this.category,
    this.applicationStatus,
  });

  final String id;
  final String? userId;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final bool isOnline;
  final double rating;
  final int reviewCount;
  final int pricePerMinute;
  final List<String> specialties;
  final String? category;
  final String? applicationStatus;

  String get trtcUserId {
    final u = userId?.trim();
    if (u != null && u.isNotEmpty) return u;
    return id;
  }

  String get displayCategory {
    if (category != null && category!.trim().isNotEmpty) return category!.trim();
    if (specialties.isNotEmpty) return specialties.first;
    return 'Canlı fal';
  }

  bool get isApproved {
    final status = applicationStatus?.trim().toLowerCase();
    if (status == null || status.isEmpty) return false;
    return status == 'approved' || status == 'active';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        bio,
        avatarUrl,
        isOnline,
        rating,
        reviewCount,
        pricePerMinute,
        specialties,
        category,
        applicationStatus,
      ];
}
