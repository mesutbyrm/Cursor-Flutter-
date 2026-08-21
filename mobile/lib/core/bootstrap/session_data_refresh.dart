import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/fortune/presentation/providers/fortune_access_providers.dart';
import '../../features/home/presentation/providers/home_providers.dart';
import '../../features/live/presentation/providers/discover_live_streams.dart';
import '../../features/live/presentation/providers/discover_voice_rooms.dart';
import '../../features/live/presentation/providers/live_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/social/presentation/utils/social_session_cache.dart';
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
  clearSocialSessionCache(ref);
  ref.invalidate(walletBalancesProvider);
  ref.invalidate(profileStatsProvider);
  ref.invalidate(fortuneAccessStateProvider);
  unawaited(ref.read(userPresenceServiceProvider).heartbeat());
}
