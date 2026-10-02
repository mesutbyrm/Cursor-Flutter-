import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_live_psychics_repository.dart';

const _session = PsychicSessionEntity(
  sessionId: 'sess_wait',
  psychic: PsychicEntity(id: 't1', name: 'Falcı', isOnline: true),
  durationMinutes: 10,
  totalJeton: 100,
);

GoRouter _router() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(
          path: '/canli-falcilar/:id/waiting',
          builder: (_, _) => const SizedBox(),
        ),
      ],
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('ağ hatasında kayıtlı seans SİLİNMEZ', (tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await PsychicSessionStore.save(_session);

    await PsychicFlow.resumeActiveClientSessions(
      router: router,
      repo: FakeLivePsychicsRepository(lookupsFail: true),
    );

    expect((await PsychicSessionStore.load())?.sessionId, 'sess_wait');
  });

  testWidgets('sunucu «seans yok» derse kayıt temizlenir', (tester) async {
    final router = _router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await PsychicSessionStore.save(_session);

    await PsychicFlow.resumeActiveClientSessions(
      router: router,
      repo: FakeLivePsychicsRepository(), // statusResult null → notFound
    );

    expect(await PsychicSessionStore.load(), isNull);
  });
}
