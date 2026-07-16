import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/services/fortune_service.dart';
import 'package:canlifal_social/services/service_utils.dart';

void main() {
  group('FortuneService.resolveSlug', () {
    test('maps English types to production slugs', () {
      expect(FortuneService.resolveSlug('coffee'), 'kahve-fali');
      expect(FortuneService.resolveSlug('tarot'), 'tarot-fali');
      expect(FortuneService.resolveSlug('dream'), 'ruya-yorumu');
      expect(FortuneService.resolveSlug('birthchart'), 'dogum-haritasi');
      expect(FortuneService.resolveSlug('kursundokme'), 'kursundokme');
    });

    test('passes through unknown slug', () {
      expect(FortuneService.resolveSlug('ozel-fal'), 'ozel-fal');
    });
  });

  group('ServiceUtils', () {
    test('unwrapMap reads success wrapper', () {
      final map = ServiceUtils.unwrapMap({
        'success': true,
        'data': {'id': '1', 'name': 'Test'},
      });
      expect(map?['id'], '1');
    });

    test('extractList from nested key', () {
      final list = ServiceUtils.extractList({
        'items': [
          {'id': 'a'},
        ],
      });
      expect(list, hasLength(1));
      expect(list.first['id'], 'a');
    });
  });
}
