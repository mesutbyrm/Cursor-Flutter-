import 'dart:io';

import 'package:canlifal_social/core/theme/app_theme.dart';
import 'package:canlifal_social/features/web_parity/domain/feature_catalog.dart';
import 'package:canlifal_social/features/web_parity/domain/parity_models.dart';
import 'package:canlifal_social/features/web_parity/presentation/pages/feature_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parityUnwrap zarfı açar, ham listeyi bozmaz', () {
    expect(parityUnwrap({'success': true, 'data': {'a': 1}}), {'a': 1});
    expect(parityUnwrap([1, 2]), [1, 2]);
    expect(parityUnwrap({'x': 1}), {'x': 1});
  });

  test('LeaderboardEntry.fromTop100 kendi satırını işaretler', () {
    final e = LeaderboardEntry.fromTop100(
      {'rank': 2, 'userId': 'u1', 'name': 'Ayşe', 'score': 120},
      selfId: 'u1',
    );
    expect(e.rank, 2);
    expect(e.score, 120);
    expect(e.isSelf, isTrue);
  });

  test('özellik kataloğunda rotalar benzersiz ve gruplar tanımlı', () {
    final routes = kFeatureCatalog.map((e) => e.route).toList();
    expect(routes.toSet().length, routes.length);
    for (final f in kFeatureCatalog) {
      expect(kFeatureGroups, contains(f.group), reason: f.label);
      expect(f.route.startsWith('/'), isTrue);
    }
    expect(kFeatureCatalog.where((e) => e.onHome), isNotEmpty);
    // Lamba Cini ve Futbol «Tüm Özellikler»den kaldırıldı.
    expect(routes, isNot(contains('/oyunlar/lamba-cini')));
    expect(routes, isNot(contains('/football')));
  });

  test('her özellik kutusunun mevcut bir görseli var', () {
    for (final f in kFeatureCatalog) {
      expect(f.image, isNotNull, reason: f.label);
      expect(File(f.image!).existsSync(), isTrue, reason: f.image);
    }
  });

  testWidgets('Tüm Özellikler sayfası her kataloğu çizer', (tester) async {
    tester.view.physicalSize = const Size(400, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(theme: AppTheme.dark(), home: const FeatureHubPage()),
      ),
    );
    await tester.pumpAndSettle();
    for (final f in kFeatureCatalog) {
      expect(find.text(f.label), findsOneWidget, reason: f.label);
    }
    expect(tester.takeException(), isNull);
  });
}
