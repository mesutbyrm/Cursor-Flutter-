import 'package:canlifal_social/features/shorts/domain/entities/short_video_entity.dart';
import 'package:canlifal_social/features/shorts/presentation/providers/shorts_playback_providers.dart';
import 'package:canlifal_social/features/shorts/presentation/utils/shorts_content_filter.dart';
import 'package:flutter_test/flutter_test.dart';

ShortVideoEntity _video({String rating = 'all'}) => ShortVideoEntity(
      id: 'v1',
      userId: 'u1',
      videoUrl: 'https://cdn.example/v.mp4',
      contentRating: rating,
    );

void main() {
  test('filterShortsForSafeSettings passes all when disabled', () {
    const settings = ShortsSafeSettings(restrictedMode: false, hideMature: false);
    final list = [_video(), _video(rating: 'mature')];
    expect(filterShortsForSafeSettings(list, settings).length, 2);
  });

  test('restrictedMode hides mature and teen', () {
    const settings = ShortsSafeSettings(restrictedMode: true, hideMature: false);
    final list = [
      _video(),
      _video(rating: 'teen'),
      _video(rating: 'mature'),
    ];
    final out = filterShortsForSafeSettings(list, settings);
    expect(out.length, 1);
    expect(out.first.contentRating, 'all');
  });
}
