import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/presentation/providers/profile_hub_providers.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/shorts/presentation/providers/shorts_providers.dart';

/// Profil — Jeton, CFC, takipçi, gönderiler birbirini beklemez.
abstract final class ProfileLoadPerf {
  static final Map<String, DateTime> _lastPrefetchByUser = {};
  static const _prefetchTtl = Duration(minutes: 3);

  /// Profil sekmesi açıldığında tüm dilimleri paralel başlat.
  static void prefetchOnOpen(WidgetRef ref, String userId) {
    final id = userId.trim();
    if (id.isEmpty) return;
    final now = DateTime.now();
    final last = _lastPrefetchByUser[id];
    if (last != null && now.difference(last) < _prefetchTtl) return;
    _lastPrefetchByUser[id] = now;
    unawaited(_warm(ref, id));
  }

  static Future<void> _warm(WidgetRef ref, String userId) async {
    unawaited(ref.read(walletBalancesProvider.future));
    unawaited(ref.read(profileStatsProvider.future));
    unawaited(ref.read(profileExtendedProvider.future));
    unawaited(ref.read(profileUserStatisticsProvider.future));
    unawaited(ref.read(userLevelProvider.future));
    unawaited(ref.read(giftsReceivedSummaryProvider.future));
    unawaited(ref.read(userAchievementsProvider.future));
    unawaited(ref.read(shortVideoProfileStatsProvider(userId).future));
  }
}
