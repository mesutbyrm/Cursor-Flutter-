import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import '../../features/profile/presentation/providers/profile_hub_providers.dart';
import '../me/me_entitlements_providers.dart';
import 'membership_capabilities.dart';

/// Backend `/api/me/membership` + yedek tier matrisi.
final membershipCapabilitiesProvider =
    FutureProvider.autoDispose<MembershipCapabilities>((ref) async {
  final profileTier =
      ref.watch(profileMembershipInfoProvider).effectiveTier;
  try {
    final raw = await ref.watch(meMembershipPackageProvider.future);
    if (raw.isEmpty) {
      return MembershipCapabilities.forTier(profileTier);
    }
    return MembershipCapabilities.parse(raw, fallbackTier: profileTier);
  } catch (_) {
    return MembershipCapabilities.forTier(profileTier);
  }
});

/// Senkron erişim — yükleme sırasında profil tier fallback.
final membershipCapabilitiesSyncProvider =
    Provider<MembershipCapabilities>((ref) {
  final async = ref.watch(membershipCapabilitiesProvider);
  final profileTier =
      ref.watch(profileMembershipInfoProvider).effectiveTier;
  return async.valueOrNull ?? MembershipCapabilities.forTier(profileTier);
});

bool membershipAllows(WidgetRef ref, String capabilityKey) {
  return ref.watch(membershipCapabilitiesSyncProvider).allows(capabilityKey);
}

/// Provider / notifier içinden capability kontrolü.
bool membershipAllowsRef(Ref ref, String capabilityKey) {
  return ref.watch(membershipCapabilitiesSyncProvider).allows(capabilityKey);
}

final membershipCapabilityAllowsProvider =
    Provider.family<bool, String>((ref, capabilityKey) {
  return ref.watch(membershipCapabilitiesSyncProvider).allows(capabilityKey);
});
