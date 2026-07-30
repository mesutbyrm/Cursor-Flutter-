import 'package:equatable/equatable.dart';

import '../../../../core/util/json_util.dart';
import 'short_video_liker.dart';

/// Kısa video içerik üreticisi analitikleri.
class ShortVideoAnalytics extends Equatable {
  const ShortVideoAnalytics({
    required this.videoId,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.savesCount = 0,
    this.avgWatchSec = 0,
    this.completionRate = 0,
    this.duetsCount = 0,
    this.profileVisits = 0,
    this.recentLikers = const [],
  });

  final String videoId;
  final int viewsCount;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final int savesCount;
  final double avgWatchSec;
  final double completionRate;
  final int duetsCount;
  final int profileVisits;
  final List<ShortVideoLiker> recentLikers;

  factory ShortVideoAnalytics.fromJson(
    String videoId,
    Map<String, dynamic> json,
  ) {
    int i(dynamic v) => (v as num?)?.toInt() ?? 0;
    double d(dynamic v) => (v as num?)?.toDouble() ?? 0;

    final stats = json['stats'] ?? json['analytics'] ?? json;
    final m = stats is Map ? Map<String, dynamic>.from(stats) : json;

    final likersRaw = pick(m, [
          'recentLikers',
          'likers',
          'likedBy',
          'likes',
        ]) ??
        pick(json, ['recentLikers', 'likers', 'likedBy']);
    final likers = <ShortVideoLiker>[];
    if (likersRaw is List) {
      for (final item in likersRaw) {
        if (item is Map) {
          likers.add(ShortVideoLiker.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return ShortVideoAnalytics(
      videoId: videoId,
      viewsCount: i(m['viewsCount'] ?? m['views'] ?? m['viewCount']),
      likesCount: i(m['likesCount'] ?? m['likes'] ?? m['likeCount']),
      commentsCount: i(m['commentsCount'] ?? m['comments']),
      sharesCount: i(m['sharesCount'] ?? m['shares']),
      savesCount: i(m['savesCount'] ?? m['saves']),
      avgWatchSec: d(m['avgWatchSec'] ?? m['averageWatchSeconds']),
      completionRate: d(m['completionRate'] ?? m['completion']),
      duetsCount: i(m['duetsCount'] ?? m['duets']),
      profileVisits: i(m['profileVisits'] ?? m['profileClicks']),
      recentLikers: likers,
    );
  }

  factory ShortVideoAnalytics.fromVideo({
    required String videoId,
    required int viewsCount,
    required int likesCount,
    required int commentsCount,
    required int sharesCount,
    required int savesCount,
  }) {
    return ShortVideoAnalytics(
      videoId: videoId,
      viewsCount: viewsCount,
      likesCount: likesCount,
      commentsCount: commentsCount,
      sharesCount: sharesCount,
      savesCount: savesCount,
    );
  }

  @override
  List<Object?> get props => [
        videoId,
        viewsCount,
        likesCount,
        sharesCount,
        recentLikers,
      ];
}
