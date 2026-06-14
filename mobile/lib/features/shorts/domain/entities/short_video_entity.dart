import 'package:equatable/equatable.dart';

class ShortVideoAuthor extends Equatable {
  const ShortVideoAuthor({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  String get label => displayName?.trim().isNotEmpty == true
      ? displayName!.trim()
      : username;

  @override
  List<Object?> get props => [id, username, displayName, avatarUrl];
}

class ShortVideoEntity extends Equatable {
  const ShortVideoEntity({
    required this.id,
    required this.userId,
    required this.videoUrl,
    this.thumbnailUrl,
    this.description,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.durationSec,
    this.createdAt,
    this.author,
    this.likedByMe = false,
    this.viewedByMe = false,
  });

  final String id;
  final String userId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? description;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final double? durationSec;
  final DateTime? createdAt;
  final ShortVideoAuthor? author;
  final bool likedByMe;
  final bool viewedByMe;

  ShortVideoEntity copyWith({
    int? viewsCount,
    int? likesCount,
    int? commentsCount,
    bool? likedByMe,
    bool? viewedByMe,
  }) {
    return ShortVideoEntity(
      id: id,
      userId: userId,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      description: description,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      durationSec: durationSec,
      createdAt: createdAt,
      author: author,
      likedByMe: likedByMe ?? this.likedByMe,
      viewedByMe: viewedByMe ?? this.viewedByMe,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        videoUrl,
        thumbnailUrl,
        description,
        viewsCount,
        likesCount,
        commentsCount,
        durationSec,
        createdAt,
        author,
        likedByMe,
        viewedByMe,
      ];
}
