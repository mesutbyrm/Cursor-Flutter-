import 'package:equatable/equatable.dart';

import 'short_video_entity.dart';

class ShortHashtagEntity extends Equatable {
  const ShortHashtagEntity({
    required this.name,
    this.videosCount = 0,
    this.viewsCount = 0,
  });

  final String name;
  final int videosCount;
  final int viewsCount;

  @override
  List<Object?> get props => [name, videosCount, viewsCount];
}

class ShortMusicEntity extends Equatable {
  const ShortMusicEntity({
    required this.id,
    required this.title,
    this.artist,
    this.coverUrl,
    this.audioUrl,
    this.usageCount = 0,
  });

  final String id;
  final String title;
  final String? artist;
  final String? coverUrl;
  final String? audioUrl;
  final int usageCount;

  @override
  List<Object?> get props => [id, title, artist, coverUrl, audioUrl, usageCount];
}

class ShortExplorePage extends Equatable {
  const ShortExplorePage({
    required this.videos,
    this.forYouVideos = const [],
    this.aiRecommendedVideos = const [],
    this.locationVideos = const [],
    this.locationLabel,
    this.trendingHashtags = const [],
    this.popularMusic = const [],
    this.nextCursor,
    this.hasMore = false,
  });

  /// Trend videolar (Keşfet grid).
  final List<ShortVideoEntity> videos;
  /// Sana özel öneriler.
  final List<ShortVideoEntity> forYouVideos;
  /// Yapay zekâ tabanlı öneriler.
  final List<ShortVideoEntity> aiRecommendedVideos;
  /// Konuma göre videolar.
  final List<ShortVideoEntity> locationVideos;
  final String? locationLabel;
  final List<ShortHashtagEntity> trendingHashtags;
  final List<ShortMusicEntity> popularMusic;
  final String? nextCursor;
  final bool hasMore;

  ShortExplorePage copyWith({
    List<ShortVideoEntity>? videos,
    List<ShortVideoEntity>? forYouVideos,
    List<ShortVideoEntity>? aiRecommendedVideos,
    List<ShortVideoEntity>? locationVideos,
    String? locationLabel,
    List<ShortHashtagEntity>? trendingHashtags,
    List<ShortMusicEntity>? popularMusic,
    String? nextCursor,
    bool? hasMore,
  }) {
    return ShortExplorePage(
      videos: videos ?? this.videos,
      forYouVideos: forYouVideos ?? this.forYouVideos,
      aiRecommendedVideos: aiRecommendedVideos ?? this.aiRecommendedVideos,
      locationVideos: locationVideos ?? this.locationVideos,
      locationLabel: locationLabel ?? this.locationLabel,
      trendingHashtags: trendingHashtags ?? this.trendingHashtags,
      popularMusic: popularMusic ?? this.popularMusic,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [
        videos,
        forYouVideos,
        aiRecommendedVideos,
        locationVideos,
        locationLabel,
        trendingHashtags,
        popularMusic,
        nextCursor,
        hasMore,
      ];
}

class ShortProfileStats extends Equatable {
  const ShortProfileStats({
    this.videosCount = 0,
    this.totalLikes = 0,
    this.totalViews = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
  });

  final int videosCount;
  final int totalLikes;
  final int totalViews;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;

  @override
  List<Object?> get props => [
        videosCount,
        totalLikes,
        totalViews,
        followersCount,
        followingCount,
        isFollowing,
      ];
}
