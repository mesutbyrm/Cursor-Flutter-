import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/fortune/presentation/providers/fortune_access_providers.dart';
import '../../features/live/presentation/providers/live_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/social/presentation/providers/social_providers.dart';

/// Oturum açıldığında veya yenilendiğinde ana veri provider'larını tazeler.
void invalidateAuthenticatedShellData(Ref ref) {
  ref.invalidate(voiceRoomsProvider);
  ref.invalidate(liveStreamsProvider);
  ref.invalidate(socialNotifierProvider);
  ref.invalidate(walletBalancesProvider);
  ref.invalidate(profileStatsProvider);
  ref.invalidate(fortuneAccessStateProvider);
}
