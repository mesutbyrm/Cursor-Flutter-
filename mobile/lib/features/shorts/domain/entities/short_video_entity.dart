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

class ShortVideoMusic extends Equatable {
  const ShortVideoMusic({
    required this.id,
    required this.title,
    this.artist,
    this.coverUrl,
    this.audioUrl,
  });

  final String id;
  final String title;
  final String? artist;
  final String? coverUrl;
  final String? audioUrl;

  @override
  List<Object?> get props => [id, title, artist, coverUrl, audioUrl];
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
    this.sharesCount = 0,
    this.savesCount = 0,
    this.durationSec,
    this.createdAt,
    this.author,
    this.likedByMe = false,
    this.viewedByMe = false,
    this.savedByMe = false,
    this.authorFollowedByMe = false,
    this.hashtags = const [],
    this.music,
    this.allowDuet = true,
    this.duetOfId,
  });

  final String id;
  final String userId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? description;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;
  final double? durationSec;
  final DateTime? createdAt;
  final ShortVideoAuthor? author;
  final bool likedByMe;
  final bool viewedByMe;
  final bool savedByMe;
  final bool authorFollowedByMe;
  final List<String> hashtags;
  final ShortVideoMusic? music;
  final bool allowDuet;
  final String? duetOfId;

  ShortVideoEntity copyWith({
    int? viewsCount,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    int? savesCount,
    bool? likedByMe,
    bool? viewedByMe,
    bool? savedByMe,
    bool? authorFollowedByMe,
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
      sharesCount: sharesCount ?? this.sharesCount,
      savesCount: savesCount ?? this.savesCount,
      durationSec: durationSec,
      createdAt: createdAt,
      author: author,
      likedByMe: likedByMe ?? this.likedByMe,
      viewedByMe: viewedByMe ?? this.viewedByMe,
      savedByMe: savedByMe ?? this.savedByMe,
      authorFollowedByMe: authorFollowedByMe ?? this.authorFollowedByMe,
      hashtags: hashtags,
      music: music,
      allowDuet: allowDuet,
      duetOfId: duetOfId,
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
        sharesCount,
        savesCount,
        durationSec,
        createdAt,
        author,
        likedByMe,
        viewedByMe,
        savedByMe,
        authorFollowedByMe,
        hashtags,
        music,
        allowDuet,
        duetOfId,
      ];
}
