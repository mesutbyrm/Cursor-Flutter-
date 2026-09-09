import 'package:canlifal_social/features/live/domain/entities/live_fortune_request_entity.dart';
import 'package:canlifal_social/features/live/domain/utils/live_fortune_display_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('liveFortuneTypePresentation', () {
    test('maps coffee to kahve falı', () {
      final p = liveFortuneTypePresentation('coffee');
      expect(p.emoji, '☕');
      expect(p.title, 'Kahve Falı');
    });

    test('maps tarot slug', () {
      final p = liveFortuneTypePresentation('tarot');
      expect(p.title, 'Tarot');
    });

    test('cta label includes İste suffix', () {
      expect(
        liveFortuneRequestCtaLabel('coffee'),
        '☕ Kahve Falı İste',
      );
    });
  });

  group('fortune request queue', () {
    test('sorts VIP before standard FIFO', () {
      final standard = LiveFortuneRequestEntity(
        id: 'a',
        streamId: 's1',
        userId: 'u1',
        displayName: 'A',
        question: 'q',
        fortuneType: 'tarot',
        priority: LiveFortunePriority.standard,
        status: LiveFortuneRequestStatus.pending,
        jetonCost: 100,
        createdAt: DateTime(2026, 1, 1),
      );
      final vip = LiveFortuneRequestEntity(
        id: 'b',
        streamId: 's1',
        userId: 'u2',
        displayName: 'B',
        question: 'q',
        fortuneType: 'coffee',
        priority: LiveFortunePriority.vip,
        status: LiveFortuneRequestStatus.pending,
        jetonCost: 500,
        createdAt: DateTime(2026, 1, 2),
      );
      final sorted = sortFortuneRequestQueue([standard, vip]);
      expect(sorted.first.id, 'b');
    });
  });
}
