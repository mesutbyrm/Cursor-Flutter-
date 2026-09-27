import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/fortune/presentation/data/fortune_similar_recommendations.dart';

void main() {
  test('similar recommendations for tarot', () {
    final slugs = FortuneSimilarRecommendations.slugsFor('tarot');
    expect(slugs, contains('katina'));
    expect(slugs, contains('melek-kartlari'));
  });
}
