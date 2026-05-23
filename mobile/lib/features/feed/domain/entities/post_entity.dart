import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user_entity.dart';

class PostEntity extends Equatable {
  const PostEntity({
    required this.id,
    required this.author,
    this.caption,
    this.mediaUrl,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.isLiked = false,
    this.createdAt,
  });

  final String id;
  final UserEntity author;
  final String? caption;
  final String? mediaUrl;
  final int likesCount;
  final int commentsCount;
  /// İzlenme / görüntülenme (yerel + sunucu).
  final int viewsCount;
  final bool isLiked;
  final DateTime? createdAt;

  /// Fal / tarot içeriklerini hikâye şeridinde göstermemek için.
  bool get isFortuneContent {
    final t = caption?.toLowerCase() ?? '';
    return t.contains('fal') ||
        t.contains('tarot') ||
        t.contains('kahve falı') ||
        t.contains('falcı');
  }

  PostEntity copyWith({
    String? id,
    UserEntity? author,
    String? caption,
    String? mediaUrl,
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    bool? isLiked,
    DateTime? createdAt,
  }) {
    return PostEntity(
      id: id ?? this.id,
      author: author ?? this.author,
      caption: caption ?? this.caption,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        author,
        caption,
        mediaUrl,
        likesCount,
        commentsCount,
        viewsCount,
        isLiked,
        createdAt,
      ];
}
