import 'package:equatable/equatable.dart';

class UserFavoriteEntity extends Equatable {
  const UserFavoriteEntity({
    required this.id,
    required this.targetType,
    required this.targetId,
    this.title,
    this.url,
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String targetType;
  final String targetId;
  final String? title;
  final String? url;
  final String? imageUrl;
  final DateTime? createdAt;

  @override
  List<Object?> get props =>
      [id, targetType, targetId, title, url, imageUrl, createdAt];
}
