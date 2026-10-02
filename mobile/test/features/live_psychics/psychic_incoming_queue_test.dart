import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_request_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_incoming_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

PsychicRequestEntity _req(String id, DateTime? createdAt) => PsychicRequestEntity(
      sessionId: id,
      clientId: 'c',
      clientName: 'Danışan',
      tellerId: 't',
      durationMinutes: 10,
      totalJeton: 100,
      fortuneType: 'general',
      createdAt: createdAt,
    );

void main() {
  test('bayat talepler elenir, en yeni talep önce gelir', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final q = container.read(psychicIncomingQueueProvider.notifier);
    final now = DateTime.now();
    q.enqueue(_req('eski-bayat', now.subtract(const Duration(minutes: 10))));
    q.enqueue(_req('yeni', now.subtract(const Duration(seconds: 5))));
    q.enqueue(_req('biraz-eski', now.subtract(const Duration(seconds: 90))));

    expect(q.takeNext()?.sessionId, 'yeni');
    expect(q.takeNext()?.sessionId, 'biraz-eski');
    // Bayat olan hiç gösterilmez ve kuyruktan temizlenir.
    expect(q.takeNext(), isNull);
    expect(container.read(psychicIncomingQueueProvider), isEmpty);
  });

  test('createdAt bilinmeyen talep (SSE/push) yine gösterilir', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final q = container.read(psychicIncomingQueueProvider.notifier);
    q.enqueue(_req('bilinmeyen', null));
    expect(q.takeNext()?.sessionId, 'bilinmeyen');
  });
}
