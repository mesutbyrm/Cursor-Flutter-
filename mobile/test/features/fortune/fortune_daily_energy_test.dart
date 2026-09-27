import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/fortune/data/fortune_birth_profile_store.dart';
import 'package:canlifal_social/features/fortune/presentation/providers/fortune_birth_profile_provider.dart';
import 'package:canlifal_social/features/fortune/presentation/providers/fortune_hub_providers.dart';
import 'package:canlifal_social/features/fortune/presentation/widgets/ultra_premium/ultra_fortune_daily_energy.dart';
import 'package:canlifal_social/features/home/data/datasources/home_remote_datasource.dart';
import 'package:canlifal_social/features/home/presentation/providers/home_providers.dart';

class _NoHoroscope implements HomeRemoteDataSource {
  @override
  Future<String?> fetchDailyHoroscope(String zodiacSign) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _host(Override insights) => ProviderScope(
  overrides: [insights],
  child: const MaterialApp(
    home: Scaffold(body: UltraFortuneDailyEnergy()),
  ),
);

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}

void main() {
  testWidgets('yüklenirken uydurma "Yüksek / Mor / 7" gösterilmez', (
    tester,
  ) async {
    final pending = Completer<FortuneDailyInsights>();
    await tester.pumpWidget(
      _host(fortuneDailyInsightsProvider.overrideWith((ref) => pending.future)),
    );
    await tester.pump();
    for (final fake in ['Yüksek', 'Mor', 'Bugün iç sesine kulak ver']) {
      expect(find.textContaining(fake), findsNothing, reason: fake);
    }
    await _dispose(tester);
  });

  testWidgets('hata durumunda tekrar dene gösterilir', (tester) async {
    await tester.pumpWidget(
      _host(
        fortuneDailyInsightsProvider.overrideWith(
          (ref) async => throw Exception('ağ yok'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.textContaining('Tekrar dene'), findsOneWidget);
    expect(find.text('Yüksek'), findsNothing);
    await _dispose(tester);
  });

  testWidgets('doğum profili yokken burca bağlı kartlar gizlenir', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        fortuneDailyInsightsProvider.overrideWith(
          (ref) async => FortuneDailyInsights.fallback(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('Şanslı Renk'.toUpperCase()), findsNothing);
    expect(find.text('Burç Mesajı'.toUpperCase()), findsNothing);
    expect(find.text('Ay Evresi'.toUpperCase()), findsOneWidget);
    expect(find.text(fortuneMoonPhaseFor(DateTime.now())), findsOneWidget);
    await _dispose(tester);
  });

  test('burç yorumu gelmezse mesajda burç adı yazar (nesne değil)', () async {
    final container = ProviderContainer(
      overrides: [
        fortuneBirthProfileProvider.overrideWith(
          (ref) async => FortuneBirthProfile(
            birthDate: DateTime(1990, 4, 5),
            birthTime: const TimeOfDay(hour: 10, minute: 0),
          ),
        ),
        homeRemoteProvider.overrideWithValue(_NoHoroscope()),
      ],
    );
    addTearDown(container.dispose);
    final data = await container.read(fortuneDailyInsightsProvider.future);
    expect(data.burcMessage, contains('Koç burcu'));
    expect(data.burcMessage, isNot(contains('Instance of')));
  });
}
