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
    this.liveStreamId,
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
  /// Aktif video yayını — yalnızca API döndürürse dolu.
  final String? liveStreamId;

  String get trtcUserId {
    final u = userId?.trim();
    if (u != null && u.isNotEmpty) return u;
    return id;
  }

  String get specialtiesLabel {
    if (specialties.isNotEmpty) {
      return specialties.take(3).join(' • ');
    }
    return displayCategory;
  }

  bool get hasLiveBroadcast =>
      liveStreamId != null && liveStreamId!.trim().isNotEmpty;

  bool get isApproved {
    final status = applicationStatus?.trim().toLowerCase();
    if (status == null || status.isEmpty) return false;
    const approved = {'approved', 'active', 'online', 'offline'};
    const rejected = {
      'pending',
      'rejected',
      'declined',
      'inactive',
    };
    if (approved.contains(status)) return true;
    if (rejected.contains(status)) return false;
    return false;
  }

  String get displayCategory {
    if (category != null && category!.trim().isNotEmpty) return category!.trim();
    if (specialties.isNotEmpty) return specialties.first;
    return 'Canlı fal';
  }

  /// Çevrimiçi falcı durum etiketi — yalnızca backend `isOnline` ile.
  String get availabilityLabel =>
      isOnline ? 'Müsait' : 'Çevrimdışı';
  bool get isUsable {
    if (id.trim().isEmpty) return false;
    if (isApproved) return true;
    final status = applicationStatus?.trim().toLowerCase();
    if (status == 'pending' || status == 'rejected' || status == 'declined') {
      return false;
    }
    return true;
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
        liveStreamId,
      ];
}
