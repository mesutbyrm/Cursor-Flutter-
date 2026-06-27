import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/social/presentation/providers/user_social_posts_notifier.dart';
import 'network_perf.dart';

/// Profil — Jeton, CFC, takipçi, gönderiler birbirini beklemez.
abstract final class ProfileLoadPerf {
  /// Profil sekmesi açıldığında tüm dilimleri paralel başlat.
  static void prefetchOnOpen(WidgetRef ref, String userId) {
    if (userId.trim().isEmpty) return;
    unawaited(_warm(ref, userId));
  }

  static Future<void> _warm(WidgetRef ref, String userId) async {
    await NetworkPerf.waitSilent([
      ref.read(walletBalancesProvider.future),
      ref.read(profileStatsProvider.future),
      ref.read(userSocialPostsNotifierProvider(userId).future),
    ]);
  }
}
