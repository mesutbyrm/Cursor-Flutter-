import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../features/vip_gold/domain/vip_tier.dart';
import '../../../features/vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../../core/auth/voice_staff_rank.dart';
import '../data/site_animation_profile_resolver.dart';
import '../domain/site_animation_catalog_entry.dart';
import '../domain/site_animation_tier.dart';
import 'site_animation_catalog_provider.dart';

SiteAnimationTier _profileTier(WidgetRef ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  final tier = ref.watch(vipTierProvider);
  final membership = switch (tier) {
    VipTier.svip => 'svip',
    VipTier.diamond => 'diamond',
    VipTier.gold => 'gold',
    VipTier.premium => 'premium',
    VipTier.basic => 'normal',
  };
  final staff = VoiceStaffRankParser.resolve(
    username: user?.username,
    chatRole: user?.role,
  );
  return SiteAnimationTier.resolve(
    membership: membership,
    staffRank: staff,
  );
}

/// Oturum kullanıcısı için site animasyon profil çerçevesi.
final resolvedSiteAnimationProfileFrameProvider =
    Provider<SiteAnimationCatalogEntry?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null || user.id.isEmpty) return null;
  final catalog = ref.watch(siteAnimationCatalogProvider).valueOrNull;
  if (catalog == null || catalog.animations.isEmpty) return null;
  return SiteAnimationProfileResolver.resolveFrame(
    userId: user.id,
    tier: _profileTier(ref),
    catalog: catalog,
  );
});

/// Oturum kullanıcısı için avatar efekti (Gold+).
final resolvedSiteAnimationAvatarEffectProvider =
    Provider<SiteAnimationCatalogEntry?>((ref) {
  final user = ref.watch(authControllerProvider).valueOrNull;
  if (user == null || user.id.isEmpty) return null;
  final catalog = ref.watch(siteAnimationCatalogProvider).valueOrNull;
  if (catalog == null || catalog.animations.isEmpty) return null;
  return SiteAnimationProfileResolver.resolveAvatarEffect(
    userId: user.id,
    tier: _profileTier(ref),
    catalog: catalog,
  );
});
