import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/feed/presentation/providers/feed_providers.dart';
import '../../features/fortune/presentation/providers/fortune_access_providers.dart';
import '../../features/home/presentation/providers/home_providers.dart';
import '../../features/live/presentation/providers/live_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/social/presentation/providers/social_providers.dart';
import '../network/dio_provider.dart';
import '../network/user_presence_service.dart';

final userPresenceServiceProvider = Provider<UserPresenceService>((ref) {
  return UserPresenceService(ref.watch(dioProvider));
});

/// Oturum açıldığında veya yenilendiğinde ana veri provider'larını tazeler.
void invalidateAuthenticatedShellData(Ref ref) {
  ref.invalidate(voiceRoomsProvider);
  ref.invalidate(liveStreamsProvider);
  ref.invalidate(homeLiveStreamsProvider);
  ref.invalidate(homeVoiceRoomsProvider);
  ref.invalidate(socialNotifierProvider);
  ref.invalidate(feedNotifierProvider);
  ref.invalidate(walletBalancesProvider);
  ref.invalidate(profileStatsProvider);
  ref.invalidate(fortuneAccessStateProvider);
  unawaited(ref.read(userPresenceServiceProvider).heartbeat());
}
