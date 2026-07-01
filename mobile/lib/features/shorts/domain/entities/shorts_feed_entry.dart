import 'package:equatable/equatable.dart';

import 'short_video_entity.dart';

/// Feed satırı — normal video veya sponsorlu reklam.
class ShortsFeedEntry extends Equatable {
  const ShortsFeedEntry._({
    required this.id,
    this.video,
    this.ad,
  });

  factory ShortsFeedEntry.video(ShortVideoEntity video) {
    return ShortsFeedEntry._(id: 'v_${video.id}', video: video);
  }

  factory ShortsFeedEntry.sponsored(ShortSponsoredAd ad) {
    return ShortsFeedEntry._(id: 'ad_${ad.id}', ad: ad);
  }

  final String id;
  final ShortVideoEntity? video;
  final ShortSponsoredAd? ad;

  bool get isVideo => video != null;
  bool get isAd => ad != null;

  @override
  List<Object?> get props => [id, video?.id, ad?.id];
}

/// Modüler sponsorlu video — ileride AdMob / GAM ile değiştirilebilir.
class ShortSponsoredAd extends Equatable {
  const ShortSponsoredAd({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.thumbnailUrl,
    this.ctaLabel = 'Daha fazla bilgi',
    this.ctaUrl,
    this.skipAfterSec = 5,
    this.provider = 'canlifal_native',
  });

  final String id;
  final String title;
  final String videoUrl;
  final String? thumbnailUrl;
  final String ctaLabel;
  final String? ctaUrl;
  final int skipAfterSec;
  final String provider;

  @override
  List<Object?> get props => [id, title, videoUrl];
}
