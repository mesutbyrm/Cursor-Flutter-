import 'package:canlifal_social/features/gifts/domain/gift_engine_parser.dart';
import 'package:canlifal_social/features/gifts/domain/gift_engine_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('priority ve displayArea backend alanlarından parse edilir', () {
    final config = GiftEngineParser.fromJson({
      'priority': 'LARGE',
      'displayArea': 'CENTER',
      'animationType': 'LOTTIE',
      'durationMs': 4200,
      'queueGapMs': 250,
      'feedDurationMs': 3000,
      'combo': 5,
      'seatEffects': ['GLOW', 'PULSE'],
    });

    expect(config.priority, GiftEnginePriority.large);
    expect(config.displayArea, GiftEngineDisplayArea.center);
    expect(config.animationType, GiftEngineAnimationType.lottie);
    expect(config.durationMs, 4200);
    expect(config.queueGapMs, 250);
    expect(config.feedDurationMs, 3000);
    expect(config.combo, 5);
    expect(config.seatEffects, contains(GiftSeatEffect.glow));
    expect(config.showComboBadge, isTrue);
  });

  test('isFullscreen bayrağı FULL_SCREEN + ULTRA üretir', () {
    final config = GiftEngineParser.fromJson({
      'isFullscreen': true,
      'displayDurationMs': 5000,
    });
    expect(config.displayArea, GiftEngineDisplayArea.fullScreen);
    expect(config.durationMs, 5000);
  });

  test('URL uzantısından video türü çıkarılır', () {
    expect(
      GiftEngineAnimationType.inferFromUrl('https://cdn.example.com/gift.mp4'),
      GiftEngineAnimationType.mp4,
    );
    expect(
      GiftEngineParser.fromJson({
        'assetUrl': 'https://cdn.example.com/rocket.webm',
      }).animationType,
      GiftEngineAnimationType.webm,
    );
  });

  test('HALF_SCREEN yarım ekran olarak parse edilir ve açık kabul edilir', () {
    final config = GiftEngineParser.fromJson({
      'displayArea': 'HALF_SCREEN',
      'assetUrl': 'https://cdn.example.com/lion.mp4',
      'animationDurationMs': 2400,
    });
    expect(config.displayArea, GiftEngineDisplayArea.halfScreen);
    expect(config.hasExplicitDisplayArea, isTrue);
    // Süre = video uzunluğu (sunucu gönderdi) — 10 sn'ye yükseltilmez.
    expect(config.durationMs, 2400);
  });

  test('konum gönderilmeyen eski video kaydı tam ekrana yükseltilir', () {
    final config = GiftEngineParser.fromJson({
      'assetUrl': 'https://cdn.example.com/old.mp4',
    });
    expect(config.displayArea, GiftEngineDisplayArea.fullScreen);
    expect(config.hasExplicitDisplayArea, isFalse);
    expect(config.durationMs, 10000);
  });
}
