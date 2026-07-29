import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/gifts/domain/gift_media_spec.dart';
import 'package:canlifal_social/features/gifts/domain/gift_media_type.dart';

void main() {
  group('GiftMediaType', () {
    test('mediaType video wins over image URL', () {
      expect(
        GiftMediaType.resolve(
          mediaType: 'video',
          url: 'https://cdn.girlive.com/gift/gifts/a.png',
        ),
        GiftMediaType.video,
      );
    });

    test('infers mp4 from URL', () {
      expect(
        GiftMediaType.resolve(
          url: 'https://cdn.girlive.com/gift/gifts/a.mp4',
        ),
        GiftMediaType.video,
      );
    });

    test('infers webp from URL', () {
      expect(
        GiftMediaType.resolve(url: 'https://example.com/a.webp'),
        GiftMediaType.webp,
      );
    });
  });

  group('GiftMediaSpec', () {
    test('aspectRatio from backend dimensions', () {
      const spec = GiftMediaSpec(
        mediaWidth: 1080,
        mediaHeight: 1920,
      );
      expect(spec.aspectRatio, closeTo(1080 / 1920, 0.001));
    });
  });
}
