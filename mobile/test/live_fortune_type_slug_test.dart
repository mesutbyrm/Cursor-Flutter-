import 'package:flutter_test/flutter_test.dart';
import 'package:canlifal_social/features/live/domain/utils/live_fortune_type_slug.dart';

void main() {
  test('liveFortuneCategoryToSlug maps Turkish labels', () {
    expect(liveFortuneCategoryToSlug('Kahve Falı'), 'coffee');
    expect(liveFortuneCategoryToSlug('Tarot Falı'), 'tarot');
    expect(liveFortuneCategoryToSlug('Numeroloji'), 'numerology');
  });

  test('isLiveFortuneTypeKey recognizes API keys', () {
    expect(isLiveFortuneTypeKey('coffee'), isTrue);
    expect(isLiveFortuneTypeKey('Sohbet'), isFalse);
  });
}
