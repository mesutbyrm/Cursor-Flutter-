import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/fortune_access_remote_datasource.dart';
import '../../data/fortune_access_local_store.dart';
import '../../domain/fortune_access_config.dart';
import '../services/fortune_access_service.dart';

final fortuneAccessLocalStoreProvider =
    FutureProvider<FortuneAccessLocalStore>((ref) {
  return FortuneAccessLocalStore.create();
});

final fortuneAccessRemoteProvider = Provider<FortuneAccessRemoteDataSource>((ref) {
  return FortuneAccessRemoteDataSource(ref.watch(dioProvider));
});

final fortuneAccessConfigProvider =
    FutureProvider<FortuneAccessConfig>((ref) async {
  final remote = ref.watch(fortuneAccessRemoteProvider);
  final fromApi = await remote.fetchSettings();
  return fromApi ?? FortuneAccessConfig.defaults;
});

class FortuneAccessState {
  const FortuneAccessState({
    required this.config,
    required this.adCredits,
    required this.adsWatchedToday,
    required this.jetonBalance,
    required this.isPremiumUnlimited,
  });

  final FortuneAccessConfig config;
  final int adCredits;
  final int adsWatchedToday;
  final int jetonBalance;
  final bool isPremiumUnlimited;

  bool get hasAdCredits => adCredits > 0;

  bool get canWatchMoreAds =>
      config.adsEnabled && adsWatchedToday < config.dailyAdLimit;

  bool get hasEnoughJeton => jetonBalance >= config.jetonCost;
}

final fortuneAccessStateProvider =
    FutureProvider<FortuneAccessState>((ref) async {
  final service = ref.watch(fortuneAccessServiceProvider);
  return service.loadState();
});

final fortuneAccessServiceProvider = Provider<FortuneAccessService>((ref) {
  return FortuneAccessService(ref);
});
