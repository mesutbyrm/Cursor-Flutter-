import 'package:canlifal_social/core/config/env.dart';
import 'package:canlifal_social/core/images/canlifal_image_urls.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CanlifalImageUrls', () {
    test('resolve relative path against site origin', () {
      expect(
        CanlifalImageUrls.resolve('/uploads/a.jpg'),
        '${Env.siteOrigin}/uploads/a.jpg',
      );
    });

    test('resolve keeps absolute https url', () {
      const raw = 'https://cdn.example.com/x.png';
      expect(CanlifalImageUrls.resolve(raw), raw);
    });

    test('thumbnail adds unsplash width param', () {
      const raw = 'https://images.unsplash.com/photo-1?ixid=abc';
      final thumb = CanlifalImageUrls.thumbnail(raw, width: 480);
      expect(thumb, contains('w=480'));
      expect(thumb, contains('fm=webp'));
    });

    test('thumbnail returns direct canlifal.com url', () {
      const raw = 'https://canlifal.com/uploads/banner.jpg';
      final thumb = CanlifalImageUrls.thumbnail(raw, width: 720);
      expect(thumb, raw);
    });

    test('full returns resolved original url', () {
      const raw = 'https://images.unsplash.com/photo-2';
      expect(CanlifalImageUrls.full(raw), raw);
    });

    test('pre-sized youtube thumb is unchanged', () {
      const raw = 'https://i.ytimg.com/vi/abc/hqdefault.jpg';
      expect(CanlifalImageUrls.thumbnail(raw, width: 320), raw);
    });
  });
}
