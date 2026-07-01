import 'package:equatable/equatable.dart';

import 'short_explore_entity.dart';

/// Yapay zekâ metadata önerisi — altyazı, özet, hashtag, müzik, kapak.
class ShortsAiMetadata extends Equatable {
  const ShortsAiMetadata({
    this.summary,
    this.hashtags = const [],
    this.subtitles,
    this.thumbnailUrls = const [],
    this.recommendedMusic = const [],
  });

  final String? summary;
  final List<String> hashtags;
  final String? subtitles;
  final List<String> thumbnailUrls;
  final List<ShortMusicEntity> recommendedMusic;

  factory ShortsAiMetadata.fromJson(Map<String, dynamic> json) {
    List<String> tags = const [];
    final rawTags = json['hashtags'] ?? json['tags'];
    if (rawTags is List) {
      tags = rawTags.map((e) => e.toString().replaceAll('#', '')).toList();
    }

    List<String> thumbs = const [];
    final rawThumbs = json['thumbnailUrls'] ?? json['thumbnails'];
    if (rawThumbs is List) {
      thumbs = rawThumbs.map((e) => e.toString()).where((u) => u.isNotEmpty).toList();
    }

    List<ShortMusicEntity> music = const [];
    final rawMusic = json['music'] ?? json['recommendedMusic'];
    if (rawMusic is List) {
      music = rawMusic.whereType<Map>().map((m) {
        final j = Map<String, dynamic>.from(m);
        return ShortMusicEntity(
          id: (j['id'] ?? '').toString(),
          title: (j['title'] ?? j['name'] ?? 'Müzik').toString(),
          artist: j['artist']?.toString(),
          coverUrl: j['coverUrl']?.toString(),
          audioUrl: j['audioUrl']?.toString(),
        );
      }).toList();
    }

    return ShortsAiMetadata(
      summary: (json['summary'] ?? json['caption'] ?? json['description'])
          ?.toString(),
      hashtags: tags,
      subtitles: (json['subtitles'] ?? json['subtitleText'])?.toString(),
      thumbnailUrls: thumbs,
      recommendedMusic: music,
    );
  }

  @override
  List<Object?> get props =>
      [summary, hashtags, subtitles, thumbnailUrls, recommendedMusic];
}

class ShortLiveClipSource extends Equatable {
  const ShortLiveClipSource({
    required this.clipUrl,
    this.thumbnailUrl,
    this.title,
    this.durationSec,
  });

  final String clipUrl;
  final String? thumbnailUrl;
  final String? title;
  final double? durationSec;

  factory ShortLiveClipSource.fromJson(Map<String, dynamic> json) {
    return ShortLiveClipSource(
      clipUrl: (json['clipUrl'] ?? json['videoUrl'] ?? json['url'] ?? '')
          .toString(),
      thumbnailUrl:
          (json['thumbnailUrl'] ?? json['thumbUrl'])?.toString(),
      title: json['title']?.toString(),
      durationSec: () {
        final v = json['durationSec'] ?? json['duration'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '');
      }(),
    );
  }

  @override
  List<Object?> get props => [clipUrl, thumbnailUrl, title];
}
