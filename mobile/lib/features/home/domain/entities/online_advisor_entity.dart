import 'package:equatable/equatable.dart';

class OnlineAdvisorEntity extends Equatable {
  const OnlineAdvisorEntity({
    required this.id,
    required this.name,
    this.category,
    this.avatarUrl,
    this.isOnline = true,
    this.rating = 0,
    this.viewerCount = 0,
    this.specialties = const [],
  });

  final String id;
  final String name;
  final String? category;
  final String? avatarUrl;
  final bool isOnline;
  final double rating;
  final int viewerCount;
  final List<String> specialties;

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        avatarUrl,
        isOnline,
        rating,
        viewerCount,
        specialties,
      ];
}
