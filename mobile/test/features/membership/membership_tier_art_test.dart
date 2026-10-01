import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/presentation/widgets/membership_tier_art.dart';

void main() {
  test('her kademenin illüstrasyon dosyası var', () {
    for (final t in MembershipTierArt.knownTiers) {
      final path = MembershipTierArt.assetFor(t)!;
      expect(File(path).existsSync(), isTrue, reason: t);
    }
    expect(MembershipTierArt.assetFor('bilinmeyen'), isNull);
  });

  testWidgets('kademe değişince taşma yok, başlık görünür', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget app(String id) => MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: MembershipTierArt(
                tierId: id,
                title: 'Diamond ile çok uzun bir üyelik başlığı',
                subtitle: 'Aylık jeton ve ayrıcalıklar burada yazılır',
              ),
            ),
          ),
        );
    await tester.pumpWidget(app('gold'));
    await tester.pumpWidget(app('diamond'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Diamond'), findsOneWidget);
  });
}
