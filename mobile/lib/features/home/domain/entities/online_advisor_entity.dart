import 'package:equatable/equatable.dart';

import '../../../live_psychics/domain/entities/psychic_entity.dart';

class OnlineAdvisorEntity extends Equatable {
  const OnlineAdvisorEntity({
    required this.id,
    required this.name,
    this.category,
    this.avatarUrl,
    this.isOnline = false,
    this.rating = 0,
    this.reviewCount = 0,
    this.pricePerMinute = 0,
    this.viewerCount = 0,
    this.specialties = const [],
    this.liveStreamId,
  });

  final String id;
  final String name;
  final String? category;
  final String? avatarUrl;
  final bool isOnline;
  final double rating;
  final int reviewCount;
  final int pricePerMinute;
  final int viewerCount;
  final List<String> specialties;
  final String? liveStreamId;

  PsychicEntity toPsychicEntity() {
    return PsychicEntity(
      id: id,
      name: name,
      avatarUrl: avatarUrl,
      isOnline: isOnline,
      rating: rating,
      reviewCount: reviewCount,
      pricePerMinute: pricePerMinute,
      specialties: specialties,
      category: category,
      liveStreamId: liveStreamId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        avatarUrl,
        isOnline,
        rating,
        reviewCount,
        pricePerMinute,
        viewerCount,
        specialties,
        liveStreamId,
      ];
}
