import '../../domain/entities/short_video_entity.dart';
import '../../domain/entities/shorts_feed_entry.dart';

/// Her 5 videodan sonra 1 sponsorlu slot enjekte eder.
List<ShortsFeedEntry> buildShortsFeedEntries(
  List<ShortVideoEntity> videos, {
  int adEveryN = 5,
}) {
  final out = <ShortsFeedEntry>[];
  var normal = 0;
  var adSlot = 0;
  for (final v in videos) {
    out.add(ShortsFeedEntry.video(v));
    normal++;
    if (normal > 0 && normal % adEveryN == 0) {
      out.add(ShortsFeedEntry.sponsored(_placeholderAd(adSlot)));
      adSlot++;
    }
  }
  return out;
}

ShortSponsoredAd _placeholderAd(int slot) {
  const demos = [
    (
      title: 'Canlifal Premium — sınırsız fal',
      url:
          'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      thumb:
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerBlazes.jpg',
    ),
    (
      title: 'Canlı falcılar — hemen bağlan',
      url:
          'https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      thumb:
          'https://storage.googleapis.com/gtv-videos-bucket/sample/images/ForBiggerEscapes.jpg',
    ),
  ];
  final demo = demos[slot % demos.length];
  return ShortSponsoredAd(
    id: 'sponsor_$slot',
    title: demo.title,
    videoUrl: demo.url,
    thumbnailUrl: demo.thumb,
    ctaUrl: 'https://canlifal.com',
    skipAfterSec: 5,
    provider: 'canlifal_native_v1',
  );
}
