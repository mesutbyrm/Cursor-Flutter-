import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/fortune/domain/entities/fortune_type_entity.dart';
import 'package:canlifal_social/features/fortune/presentation/data/fortune_similar_recommendations.dart';
import 'package:canlifal_social/features/fortune/presentation/services/fortune_energy_scorer.dart';

void main() {
  test('similar recommendations for tarot', () {
    final slugs = FortuneSimilarRecommendations.slugsFor('tarot');
    expect(slugs, contains('katina'));
    expect(slugs, contains('melek-kartlari'));
  });

  test('energy scores stay within 0-100', () {
    const type = FortuneTypeEntity(
      id: 'tarot',
      slug: 'tarot',
      title: 'Tarot',
      description: 'test',
      emoji: '🃏',
      accent: Color(0xFFB832FF),
      kind: FortuneSessionKind.tarotCards,
      ctaLabel: 'Aç',
    );
    final scores = FortuneEnergyScores.fromResult(
      FortuneReadingResult(
        type: type,
        summary: 'Test özeti',
        detail: 'Detay metni',
      ),
    );
    expect(scores.energy, inInclusiveRange(0, 100));
    expect(scores.love, inInclusiveRange(0, 100));
    expect(scores.luck, inInclusiveRange(0, 100));
  });
}
