import 'package:canlifal_social/features/content_hub/data/native_feature_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nativeFeatureSafeRoute', () {
    test('blog hub kartı kendi hubuna dönmez', () {
      expect(
        nativeFeatureSafeRoute(
          routeRaw: '/blog-hub',
          fallbackRoute: '/blog-hub',
          slug: 'kahve-fali',
          id: '1',
        ),
        '/blog/kahve-fali',
      );
    });

    test('ünlü ve fan kulübü detay yolu üretir', () {
      expect(
        nativeFeatureSafeRoute(
          routeRaw: null,
          fallbackRoute: '/celebrities-hub',
          id: 'star-9',
        ),
        '/celebrities/star-9',
      );
      expect(
        nativeFeatureSafeRoute(
          routeRaw: '/fan-club-hub',
          fallbackRoute: '/fan-club-hub',
          id: 'club-3',
        ),
        '/fan-club/club-3',
      );
    });

    test('rüya kartı detay yoluna gider', () {
      expect(
        nativeFeatureSafeRoute(
          routeRaw: null,
          fallbackRoute: '/dreams-hub',
          id: 'ruya-1',
        ),
        '/dreams/ruya-1',
      );
      expect(
        nativeFeatureSafeRoute(
          routeRaw: '/dreams-hub',
          fallbackRoute: '/dreams-hub',
          slug: 'ay-isigi',
          id: 'ignored',
        ),
        '/dreams/ay-isigi',
      );
    });

    test('geçerli native yol korunur', () {
      expect(
        nativeFeatureSafeRoute(
          routeRaw: '/blog/ozel-yazi',
          fallbackRoute: '/blog-hub',
          id: 'ignored',
        ),
        '/blog/ozel-yazi',
      );
    });
  });
}
