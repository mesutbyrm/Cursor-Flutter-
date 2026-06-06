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
    this.fortuneType,
    this.viewCount = 0,
    this.isAutoShare = false,
    this.fortuneCount = 0,
    this.postType,
    this.likedByMe = false,
  });

  final String id;
  final UserEntity author;
  final String? caption;
  final String? mediaUrl;
  final int likesCount;
  final int commentsCount;
  /// Görüntülenme (UI + yerel sayaç; akış kartında kullanılır).
  final int viewsCount;
  /// Yerel optimistik beğeni (feed kartı).
  final bool isLiked;
  final DateTime? createdAt;
  final String? fortuneType;
  final int viewCount;
  final bool isAutoShare;
  final int fortuneCount;
  final String? postType;
  /// Oturumlu kullanıcı bu gönderiyi beğendi mi (API).
  final bool likedByMe;

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
    String? fortuneType,
    int? viewCount,
    bool? isAutoShare,
    int? fortuneCount,
    String? postType,
    bool? likedByMe,
  }) {
    final nextLiked = isLiked ?? likedByMe;
    return PostEntity(
      id: id ?? this.id,
      author: author ?? this.author,
      caption: caption ?? this.caption,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isLiked: nextLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
      fortuneType: fortuneType ?? this.fortuneType,
      viewCount: viewCount ?? this.viewCount,
      isAutoShare: isAutoShare ?? this.isAutoShare,
      fortuneCount: fortuneCount ?? this.fortuneCount,
      postType: postType ?? this.postType,
      likedByMe: nextLiked ?? this.likedByMe,
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
        fortuneType,
        viewCount,
        isAutoShare,
        fortuneCount,
        postType,
        likedByMe,
      ];
}
