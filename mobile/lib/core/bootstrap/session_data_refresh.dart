import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/cosmetics/presentation/providers/cosmetics_providers.dart';
import '../../features/fortune/presentation/providers/fortune_access_providers.dart';
import '../../features/home/presentation/providers/home_providers.dart';
import '../../features/live/presentation/providers/discover_live_streams.dart';
import '../../features/live/presentation/providers/discover_voice_rooms.dart';
import '../../features/live/presentation/providers/live_providers.dart';
import '../../features/membership/presentation/controllers/membership_controller.dart';
import '../../features/profile/presentation/providers/payment_requests_notifier.dart';
import '../../features/profile/presentation/providers/profile_hub_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/social/presentation/providers/social_providers.dart';
import '../network/dio_provider.dart';
import '../network/user_presence_service.dart';

final userPresenceServiceProvider = Provider<UserPresenceService>((ref) {
  return UserPresenceService(ref.watch(dioProvider));
});

/// Oturum açıldığında veya yenilendiğinde ana veri provider'larını tazeler.
void invalidateAuthenticatedShellData(Ref ref) {
  invalidateDiscoverVoiceRooms(ref);
  invalidateDiscoverLiveStreams(ref);
  ref.invalidate(homeVoiceRoomsProvider);
  ref.invalidate(socialNotifierProvider);
  clearAuthenticatedUserCache(ref);
  unawaited(ref.read(userPresenceServiceProvider).heartbeat());
}

/// Kullanıcıya özel cache — logout veya hesap değişiminde temizlenir.
void clearAuthenticatedUserCache(Ref ref) {
  ref.invalidate(walletBalancesProvider);
  ref.invalidate(profileStatsProvider);
  ref.invalidate(profileExtendedProvider);
  ref.invalidate(profileUserStatisticsProvider);
  ref.invalidate(userLevelProvider);
  ref.invalidate(userAchievementsProvider);
  ref.invalidate(giftsReceivedSummaryProvider);
  ref.invalidate(broadcastHistoryProvider);
  ref.invalidate(profileActivityProvider);
  ref.invalidate(jetonPackagesProvider);
  ref.invalidate(paymentConfigProvider);
  ref.invalidate(paymentMethodsProvider);
  ref.invalidate(referralInfoProvider);
  ref.invalidate(allPaymentRequestsProvider);
  ref.invalidate(fortuneAccessStateProvider);
  ref.invalidate(membershipBadgesCatalogProvider);
  ref.invalidate(membershipCatalogProvider);
  ref.invalidate(membershipControllerProvider);
  ref.invalidate(paymentRequestsNotifierProvider);
  ref.invalidate(resolvedProfileFrameProvider);
  ref.invalidate(resolvedNameEffectProvider);
  ref.invalidate(resolvedMembershipBadgeProvider);
  ref.invalidate(resolvedProfileEffectProvider);
}
