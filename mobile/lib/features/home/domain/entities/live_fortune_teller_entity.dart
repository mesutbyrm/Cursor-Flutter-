import 'package:equatable/equatable.dart';

/// canlifal.com `LiveFortuneTeller` — §3.2 Canlı Falcı Sistemi.
class LiveFortuneTellerEntity extends Equatable {
  const LiveFortuneTellerEntity({
    required this.id,
    required this.name,
    this.userId,
    this.bio,
    this.avatarUrl,
    this.isOnline = false,
    this.rating = 0,
    this.reviewCount = 0,
    this.pricePerMinute = 0,
    this.level,
    this.specialties = const [],
    this.category,
  });

  final String id;
  /// TRTC yayıncı kimliği — profil `id` ile aynı olmayabilir.
  final String? userId;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final bool isOnline;
  final double rating;
  final int reviewCount;
  final int pricePerMinute;
  final String? level;
  final List<String> specialties;
  final String? category;

  String get displayCategory {
    if (category != null && category!.trim().isNotEmpty) return category!.trim();
    if (specialties.isNotEmpty) return specialties.first;
    return 'Canlı fal';
  }

  String? get levelLabel {
    final l = level?.trim().toLowerCase();
    if (l == null || l.isEmpty) return null;
    return switch (l) {
      'bronze' => 'Bronz',
      'silver' => 'Gümüş',
      'gold' => 'Altın',
      'diamond' => 'Elmas',
      _ => level,
    };
  }

  String get trtcUserId {
    final u = userId?.trim();
    if (u != null && u.isNotEmpty) return u;
    return id;
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
        level,
        specialties,
        category,
      ];
}
