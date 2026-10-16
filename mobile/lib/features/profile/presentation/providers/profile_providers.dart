import 'package:canlifal_social/core/l10n/tr_labels.dart';
import 'package:canlifal_social/features/gifts/domain/gift_entity.dart';
import 'package:canlifal_social/features/gifts/presentation/providers/gift_catalog_index_provider.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/network/loading_timeout.dart';
import '../../../../core/network/token_storage.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../wallet/domain/cfc_payment_request_entity.dart';
import '../../../wallet/domain/wallet_balances.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../shorts/presentation/providers/shorts_providers.dart';
import '../../domain/entities/jeton_package_entity.dart';
import '../../domain/entities/profile_extended_entity.dart';
import '../../domain/entities/profile_stats_entity.dart';
import '../../domain/entities/payment_config_entity.dart';
import '../../domain/entities/payment_method_entity.dart';
import '../../domain/entities/referral_info_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/datasources/canlifal_user_api_datasource.dart';
import '../../data/datasources/achievements_remote_datasource.dart';
import '../../data/datasources/daily_tasks_remote_datasource.dart';
import '../../data/datasources/profile_remote_datasource.dart';
import '../../../home/data/datasources/mobile_compound_remote_datasource.dart';
import '../../domain/entities/daily_task_entity.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../../gifts/presentation/providers/gift_insights_providers.dart';
import '../../../gifts/domain/gift_history_item.dart';

final profileRemoteProvider = Provider<ProfileRemoteDataSource>((ref) {
  return ProfileRemoteDataSource(
    ref.watch(dioProvider),
    ref.watch(mobileCompoundRemoteProvider),
  );
});

final achievementsRemoteProvider = Provider<AchievementsRemoteDataSource>((ref) {
  return AchievementsRemoteDataSource(ref.watch(dioProvider));
});

final dailyTasksRemoteProvider = Provider<DailyTasksRemoteDataSource>((ref) {
  return DailyTasksRemoteDataSource(ref.watch(dioProvider));
});

final userDailyTasksProvider =
    FutureProvider<List<DailyTaskEntity>>((ref) async {
  return ref.watch(dailyTasksRemoteProvider).fetchDailyTasks();
});

final userLevelProvider = FutureProvider<UserLevelEntity>((ref) async {
  ref.keepAlive();
  return ref.watch(dailyTasksRemoteProvider).fetchUserLevel();
});

final userAchievementsProvider =
    FutureProvider<List<AchievementEntity>>((ref) async {
  ref.keepAlive();
  return ref.watch(achievementsRemoteProvider).fetchAchievements();
});

final canlifalUserApiProvider = Provider<CanlifalUserApiDataSource>((ref) {
  return CanlifalUserApiDataSource(ref.watch(dioProvider));
});

final walletRemoteProvider = Provider<WalletRemoteDataSource>((ref) {
  return WalletRemoteDataSource(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(
    ref.watch(profileRemoteProvider),
    ref.watch(canlifalUserApiProvider),
  );
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(walletRemoteProvider));
});

/// Jeton/cüzdan bakiyesi — oturum boyunca cache, gereksiz API tekrarı yok.
class WalletBalancesNotifier extends AsyncNotifier<WalletBalances> {
  static const _fetchTimeout = Duration(seconds: 12);
  static const _minRefreshGap = Duration(seconds: 20);

  DateTime? _lastFetchedAt;
  WalletBalances? _cached;

  void _resetLocalCache() {
    _cached = null;
    _lastFetchedAt = null;
  }

  @override
  Future<WalletBalances> build() async {
    ref.keepAlive();
    ref.listen<String?>(
      authControllerProvider.select((a) => a.valueOrNull?.id),
      (prev, next) {
        if (prev != null && prev != next) {
          _resetLocalCache();
          state = const AsyncValue.loading();
          unawaited(refresh(force: true));
        }
        if (next == null) {
          _resetLocalCache();
          state = const AsyncValue.data(WalletBalances.empty);
        }
      },
    );
    final authJeton = ref.read(authControllerProvider).valueOrNull?.coinBalance;
    if (authJeton != null && _cached == null) {
      _cached = WalletBalances(jeton: authJeton);
      _lastFetchedAt = DateTime.now();
    }
    Future.microtask(() => refresh(force: false));
    return _cached ?? WalletBalances.empty;
  }

  Future<WalletBalances> refresh({bool force = false}) async {
    if (!force &&
        _cached != null &&
        _lastFetchedAt != null &&
        DateTime.now().difference(_lastFetchedAt!) < _minRefreshGap) {
      return _cached!;
    }
    state = const AsyncLoading<WalletBalances>().copyWithPrevious(state);
    final next = await AsyncValue.guard(() => _load(force: true));
    state = next;
    return next.value ?? _cached ?? WalletBalances.empty;
  }

  /// Hediye SSE/REST yanıtındaki `remainingBalance` — anında UI senkronu.
  void applyJetonFromServer(int jeton) {
    if (jeton < 0) return;
    final base = _cached ?? state.valueOrNull ?? WalletBalances.empty;
    final next = base.copyWith(jeton: jeton);
    _cached = next;
    _lastFetchedAt = DateTime.now();
    state = AsyncData(next);
  }

  Future<WalletBalances> _load({required bool force}) async {
    if (!force && _cached != null) return _cached!;
    final balances = await LoadingTimeout.run(
      ref.read(walletRepositoryProvider).balances(forceRefresh: force),
      timeout: _fetchTimeout,
      message: 'Cüzdan yüklenemedi',
    );
    _cached = balances;
    _lastFetchedAt = DateTime.now();
    return balances;
  }
}

final walletBalancesProvider =
    AsyncNotifierProvider<WalletBalancesNotifier, WalletBalances>(
  WalletBalancesNotifier.new,
);

final coinBalanceProvider = Provider<int?>((ref) {
  return ref.watch(walletBalancesProvider).valueOrNull?.jeton;
});

void invalidateWalletCacheFromRef(Ref ref) {
  ref.read(walletBalancesProvider.notifier).refresh(force: true);
}

extension WalletCacheRefresh on WidgetRef {
  Future<void> refreshWalletCache({bool force = true}) {
    return read(walletBalancesProvider.notifier).refresh(force: force);
  }
}

final userProfileProvider =
    FutureProvider.family<UserEntity, String>((ref, userId) async {
  return ref.watch(profileRepositoryProvider).getUser(userId);
});

final userProfileExtendedProvider =
    FutureProvider.family<ProfileExtendedEntity, String>((ref, userId) async {
  return ref.watch(profileRepositoryProvider).getUserExtended(userId);
});

final paymentConfigProvider = FutureProvider<PaymentConfigEntity>((ref) async {
  return ref.watch(walletRepositoryProvider).paymentConfig();
});

final paymentMethodsProvider =
    FutureProvider<List<PaymentMethodEntity>>((ref) async {
  ref.keepAlive();
  return ref.watch(walletRepositoryProvider).paymentMethods();
});

final jetonPackagesProvider =
    FutureProvider<List<JetonPackageEntity>>((ref) async {
  ref.keepAlive();
  return ref.watch(walletRepositoryProvider).jetonPackages();
});

final referralInfoProvider = FutureProvider<ReferralInfoEntity>((ref) async {
  return ref.watch(walletRepositoryProvider).referralInfo();
});

/// Reklam ödülü: önce sunucu doğrulamalı (AdMob SSV) ödülü bekler; bakiye
/// artarsa istemci ek çağrı yapmaz (çifte ödül yok). SSV ödülü gelmezse
/// (bayrak kapalı / gecikme) eski `watch-ad` uç noktasına düşer.
final watchAdCreditProvider = FutureProvider.autoDispose<int>((ref) async {
  final notifier = ref.read(walletBalancesProvider.notifier);
  int total(WalletBalances b) => b.jeton + b.cfc + (b.fortuneAdCredits ?? 0);

  final before = total(await notifier.refresh(force: true));
  for (var i = 0; i < 2; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    final gained = total(await notifier.refresh(force: true)) - before;
    if (gained > 0) return gained;
  }
  final reward = await ref.watch(walletRepositoryProvider).watchAdCredit();
  await notifier.refresh(force: true);
  return reward;
});

final profileStatsProvider = FutureProvider<ProfileStatsEntity>((ref) async {
  ref.keepAlive();
  var stats = await LoadingTimeout.run(
    ref.watch(profileRepositoryProvider).myStats(),
    // 3 sn yavaş bağlantıda zaman aşımına düşüp beğeni/sayıları 0 gösteriyordu.
    timeout: const Duration(seconds: 10),
    message: 'Profil istatistikleri yüklenemedi',
  );
  if (stats.giftsSentCount == 0 && stats.giftsSentCoins == 0) {
    try {
      final sent = await ref
          .read(giftInsightsRemoteProvider)
          .fetchHistory(direction: 'sent', limit: 80);
      var count = 0;
      var coins = 0;
      for (final item in sent) {
        if (item.isRefunded) continue;
        count++;
        coins += item.amount;
      }
      if (count > 0 || coins > 0) {
        stats = ProfileStatsEntity(
          liveStreams: stats.liveStreams,
          likes: stats.likes,
          followers: stats.followers,
          following: stats.following,
          giftsReceivedCount: stats.giftsReceivedCount,
          giftsReceivedCoins: stats.giftsReceivedCoins,
          giftsSentCount: count,
          giftsSentCoins: coins,
          earningsJeton: stats.earningsJeton,
          approvedTopUpTotal: stats.approvedTopUpTotal,
          profileViews: stats.profileViews,
        );
      }
    } catch (_) {}
  }
  // Beğeni 0 geliyorsa (eski sunucu yalnız gönderi beğenisini sayıyordu)
  // kısa video + gönderi beğenilerinden yedek toplam alınır.
  if (stats.likes == 0) {
    var likes = 0;
    try {
      final ext = await ref.read(profileRepositoryProvider).userStatistics();
      likes = ext.likesReceived;
    } catch (_) {}
    try {
      final me = ref.read(authControllerProvider).valueOrNull?.id;
      if (me != null && me.isNotEmpty) {
        final shorts =
            await ref.read(shortsRepositoryProvider).fetchProfileStats(me);
        likes += shorts.totalLikes;
      }
    } catch (_) {}
    if (likes > 0) stats = stats.withLikes(likes);
  }
  return stats;
});

/// Alınan hediyeler — aynı hediye tek satırda, toplam ADET ile.
/// Önceden `/api/user/received-gifts` her gönderimi ayrı satır ve «×0»
/// olarak döndürüyordu; insights geçmişi gruplanır, eski uç yedektir.
final giftsReceivedSummaryProvider =
    FutureProvider<List<GiftReceivedSummaryEntity>>((ref) async {
  ref.keepAlive();
  try {
    final history = await ref
        .read(giftInsightsRemoteProvider)
        .fetchHistory(direction: 'received', limit: 200);
    if (history.isNotEmpty) {
      return _aggregateGiftHistory(
        history,
        ref.read(allGiftCatalogByIdProvider),
      );
    }
  } catch (_) {}
  final legacy =
      await ref.watch(profileRepositoryProvider).giftsReceivedSummary();
  return _aggregateSummaries(legacy);
});

List<GiftReceivedSummaryEntity> _aggregateSummaries(
  List<GiftReceivedSummaryEntity> rows,
) {
  final map = <String, GiftReceivedSummaryEntity>{};
  for (final r in rows) {
    final name = TrLabels.giftName(r.name);
    final key = name.toLowerCase();
    final add = r.count > 0 ? r.count : 1;
    final prev = map[key];
    map[key] = GiftReceivedSummaryEntity(
      name: name,
      icon: prev?.icon ?? r.icon,
      count: (prev?.count ?? 0) + add,
      coins: (prev?.coins ?? 0) + r.coins,
    );
  }
  return map.values.toList()..sort((a, b) => b.count.compareTo(a.count));
}

List<GiftReceivedSummaryEntity> _aggregateGiftHistory(
  List<GiftHistoryItem> items,
  Map<String, GiftEntity> catalog,
) {
  final map = <String, GiftReceivedSummaryEntity>{};
  for (final item in items) {
    if (item.isRefunded) continue;
    final cat = lookupGiftCatalog(catalog, item.giftId ?? '');
    final name = (cat?.name.trim().isNotEmpty == true)
        ? cat!.name.trim()
        : TrLabels.giftName(item.giftName);
    final key = (item.giftId?.trim().isNotEmpty == true)
        ? item.giftId!.trim().toLowerCase()
        : name.toLowerCase();
    if (key.isEmpty) continue;
    final prev = map[key];
    map[key] = GiftReceivedSummaryEntity(
      name: prev?.name ?? name,
      icon: prev?.icon ?? item.giftIcon ?? '🎁',
      count: (prev?.count ?? 0) + item.quantity,
      coins: (prev?.coins ?? 0) + item.amount,
    );
  }
  final list = map.values.toList()
    ..sort((a, b) => b.count.compareTo(a.count));
  return list;
}

final giftsSentSummaryProvider =
    FutureProvider<List<GiftReceivedSummaryEntity>>((ref) async {
  ref.keepAlive();
  final history = await ref
      .read(giftInsightsRemoteProvider)
      .fetchHistory(direction: 'sent', limit: 200);
  return _aggregateGiftHistory(history, ref.read(allGiftCatalogByIdProvider));
});

final broadcastHistoryProvider =
    FutureProvider<List<BroadcastHistoryItemEntity>>((ref) async {
  return ref.watch(profileRepositoryProvider).broadcastHistory();
});

final profileActivityProvider =
    FutureProvider<List<ProfileActivityItemEntity>>((ref) async {
  return ref.watch(profileRepositoryProvider).myActivity();
});

final allPaymentRequestsProvider =
    FutureProvider.autoDispose<List<CfcPaymentRequestEntity>>((ref) async {
  return ref.watch(walletRepositoryProvider).myPaymentRequests();
});

/// Takipçi listesi — profil ve sosyal ekranlar ortak cache.
final userFollowersProvider =
    FutureProvider.family<List<UserEntity>, String>((ref, userId) async {
  if (userId.trim().isEmpty) return const [];
  return ref.watch(profileRemoteProvider).followers(userId);
});

/// Takip edilenler listesi.
final userFollowingProvider =
    FutureProvider.family<List<UserEntity>, String>((ref, userId) async {
  if (userId.trim().isEmpty) return const [];
  return ref.watch(profileRemoteProvider).following(userId);
});

/// Yayın ekipmanı tercihleri (oturum boyunca).
final equipmentSettingsProvider =
    NotifierProvider<EquipmentSettingsNotifier, EquipmentSettings>(
  EquipmentSettingsNotifier.new,
);

class EquipmentSettings {
  const EquipmentSettings({
    this.micEnabled = true,
    this.cameraEnabled = true,
    this.beautyFilter = false,
    this.noiseCancel = true,
    this.hdStream = true,
  });

  final bool micEnabled;
  final bool cameraEnabled;
  final bool beautyFilter;
  final bool noiseCancel;
  final bool hdStream;

  EquipmentSettings copyWith({
    bool? micEnabled,
    bool? cameraEnabled,
    bool? beautyFilter,
    bool? noiseCancel,
    bool? hdStream,
  }) {
    return EquipmentSettings(
      micEnabled: micEnabled ?? this.micEnabled,
      cameraEnabled: cameraEnabled ?? this.cameraEnabled,
      beautyFilter: beautyFilter ?? this.beautyFilter,
      noiseCancel: noiseCancel ?? this.noiseCancel,
      hdStream: hdStream ?? this.hdStream,
    );
  }
}

class EquipmentSettingsNotifier extends Notifier<EquipmentSettings> {
  @override
  EquipmentSettings build() => const EquipmentSettings();

  void toggle(String key, bool value) {
    switch (key) {
      case 'mic':
        state = state.copyWith(micEnabled: value);
      case 'camera':
        state = state.copyWith(cameraEnabled: value);
      case 'beauty':
        state = state.copyWith(beautyFilter: value);
      case 'noise':
        state = state.copyWith(noiseCancel: value);
      case 'hd':
        state = state.copyWith(hdStream: value);
    }
  }
}
