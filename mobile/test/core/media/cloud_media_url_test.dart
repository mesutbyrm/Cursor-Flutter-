import 'package:canlifal_social/core/media/cloud_media_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CloudMediaUrl', () {
    test('resolves gift R2 path to CDN base', () {
      expect(
        CloudMediaUrl.resolve('gift/gifts/uuid.mp4'),
        'https://cdn.girlive.com/gift/gifts/uuid.mp4',
      );
    });

    test('keeps absolute http URLs', () {
      const url = 'https://cdn.girlive.com/gift/gifts/x.mp4';
      expect(CloudMediaUrl.resolve(url), url);
    });

    test('resolves site-relative paths', () {
      expect(
        CloudMediaUrl.resolve('/uploads/old.png', siteOrigin: 'https://canlifal.com'),
        'https://canlifal.com/uploads/old.png',
      );
    });
  });
}
