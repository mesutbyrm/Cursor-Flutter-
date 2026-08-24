import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/cosmetics/domain/cosmetic_effect_kind.dart';
import 'package:canlifal_social/features/cosmetics/domain/cosmetic_item.dart';
import 'package:canlifal_social/features/cosmetics/domain/cosmetic_slot.dart';
import 'package:canlifal_social/features/cosmetics/domain/user_cosmetic_loadout.dart';
import 'package:canlifal_social/features/cosmetics/presentation/providers/cosmetics_providers.dart';
import 'package:canlifal_social/features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import 'package:canlifal_social/features/profile/presentation/profile_hub/profile_hub_membership_badges_section.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_hub_providers.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/vip_gold/presentation/providers/vip_membership_provider.dart';

void main() {
  group('ProfileHubMembershipBadgesSection', () {
    testWidgets('ücretsiz kullanıcı rozet alt başlığı', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            profileMembershipInfoProvider.overrideWith(
              (ref) => const ProfileMembershipInfo(
                raw: 'basic',
                tier: VipTier.basic,
              ),
            ),
            vipTierProvider.overrideWith((ref) => VipTier.basic),
            membershipBadgesCatalogProvider.overrideWith(
              (ref) async => const [
                CosmeticItem(
                  id: 'b1',
                  slot: CosmeticSlot.badge,
                  name: 'Gold Rozet',
                  effectKind: CosmeticEffectKind.neonGlow,
                  requiredTier: VipTier.gold,
                ),
                CosmeticItem(
                  id: 'b2',
                  slot: CosmeticSlot.badge,
                  name: 'Diamond Rozet',
                  effectKind: CosmeticEffectKind.neonGlow,
                  requiredTier: VipTier.diamond,
                ),
              ],
            ),
            cosmeticLoadoutProvider.overrideWith(_EmptyLoadoutNotifier.new),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ProfileHubMembershipBadgesSection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Üyelik Rozetleri'), findsOneWidget);
      expect(find.textContaining('0/2 rozet açık'), findsOneWidget);
      expect(find.textContaining('plan yükseltin'), findsOneWidget);
    });
  });
}

class _EmptyLoadoutNotifier extends CosmeticLoadoutNotifier {
  @override
  Future<UserCosmeticLoadout> build() async => const UserCosmeticLoadout.empty();
}
