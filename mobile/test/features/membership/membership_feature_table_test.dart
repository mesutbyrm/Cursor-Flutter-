import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/membership/domain/membership_model.dart';
import 'package:canlifal_social/features/membership/domain/membership_package_entity.dart';
import 'package:canlifal_social/features/membership/presentation/widgets/feature_table.dart';

void main() {
  group('MembershipFeatureTable', () {
    testWidgets('Fal indirimi satırı ayrı eklenir', (tester) async {
      final tiers = [
        for (final t in MembershipCatalogData.tiers)
          MembershipTierModel(
            id: t.id,
            title: t.title,
            subtitle: t.subtitle,
            monthlyTokens: t.monthlyTokens,
            monthlyPriceTry: t.monthlyPriceTry,
            accent: t.accent,
            badgeIcon: t.badgeIcon,
            glow: t.glow,
            falDiscountPercent:
                t.id == MembershipTierId.gold ? 10 : t.falDiscountPercent,
          ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: MembershipFeatureTable(
                  selectedTier: MembershipTierId.gold,
                  tiers: tiers,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fal indirimi'), findsOneWidget);
      expect(find.text('%10'), findsOneWidget);
      expect(find.text('Jeton Alımında İndirim'), findsNothing);
    });

    testWidgets('paket features[] satırları eklenir', (tester) async {
      final tiers = [
        for (final t in MembershipCatalogData.tiers)
          MembershipTierModel(
            id: t.id,
            title: t.title,
            subtitle: t.subtitle,
            monthlyTokens: t.monthlyTokens,
            monthlyPriceTry: t.monthlyPriceTry,
            accent: t.accent,
            badgeIcon: t.badgeIcon,
            glow: t.glow,
            featureHighlights: t.id == MembershipTierId.gold
                ? const [
                    MembershipFeatureHighlightEntity(
                      id: 'vip_rooms',
                      title: 'VIP Odalar',
                    ),
                  ]
                : const [],
          ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: MembershipFeatureTable(
                  selectedTier: MembershipTierId.gold,
                  tiers: tiers,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VIP Odalar'), findsOneWidget);
    });
  });
}
