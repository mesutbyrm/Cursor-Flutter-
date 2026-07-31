import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/core/util/service_utils.dart';
import 'package:canlifal_social/features/fortune/domain/fortune_type_slug.dart';

void main() {
  group('FortuneTypeSlug.resolve', () {
    test('maps English types to production slugs', () {
      expect(FortuneTypeSlug.resolve('coffee'), 'kahve-fali');
      expect(FortuneTypeSlug.resolve('tarot'), 'tarot-fali');
      expect(FortuneTypeSlug.resolve('dream'), 'ruya-yorumu');
      expect(FortuneTypeSlug.resolve('birthchart'), 'dogum-haritasi');
      expect(FortuneTypeSlug.resolve('kursundokme'), 'kursundokme');
    });

    test('passes through unknown slug', () {
      expect(FortuneTypeSlug.resolve('ozel-fal'), 'ozel-fal');
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
