import 'package:canlifal_social/features/shorts/domain/entities/short_video_entity.dart';
import 'package:canlifal_social/features/shorts/presentation/utils/shorts_feed_entries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildShortsFeedEntries returns only backend videos (no fake ads)', () {
    const videos = [
      ShortVideoEntity(id: 'v1', userId: 'u1', videoUrl: 'https://cdn.example/a.mp4'),
      ShortVideoEntity(id: 'v2', userId: 'u1', videoUrl: 'https://cdn.example/b.mp4'),
      ShortVideoEntity(id: 'v3', userId: 'u1', videoUrl: 'https://cdn.example/c.mp4'),
      ShortVideoEntity(id: 'v4', userId: 'u1', videoUrl: 'https://cdn.example/d.mp4'),
      ShortVideoEntity(id: 'v5', userId: 'u1', videoUrl: 'https://cdn.example/e.mp4'),
      ShortVideoEntity(id: 'v6', userId: 'u1', videoUrl: 'https://cdn.example/f.mp4'),
    ];
    final entries = buildShortsFeedEntries(videos);
    expect(entries.length, videos.length);
    expect(entries.every((e) => e.isVideo), isTrue);
    expect(entries.any((e) => e.isAd), isFalse);
  });
}
