import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/performance/network_perf.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../vip_gold/presentation/providers/vip_membership_provider.dart';
import '../../data/datasources/fortune_access_remote_datasource.dart';
import '../../data/fortune_access_local_store.dart';
import '../../data/services/rewarded_ad_service.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../../domain/fortune_access_config.dart';
import '../providers/fortune_access_providers.dart';

/// AI fal erişim kuralları — reklam hakkı, jeton, premium.
class FortuneAccessService {
  FortuneAccessService(this._ref);

  final Ref _ref;

  Future<FortuneAccessLocalStore> _store() =>
      _ref.read(fortuneAccessLocalStoreProvider.future);

  FortuneAccessRemoteDataSource get _remote =>
      _ref.read(fortuneAccessRemoteProvider);

  /// Günlük fal ve misafir oturumu ücret kapısından muaf.
  bool isGateRequired(FortuneTypeEntity type, {required bool isAuthenticated}) {
    if (!isAuthenticated || type.isDaily) return false;
    return true;
  }

  Future<FortuneAccessState> loadState() async {
    final pair = await NetworkPerf.parallel([
      _ref.read(fortuneAccessConfigProvider.future),
      _store(),
    ]);
    final config = pair[0] as FortuneAccessConfig;
    final store = pair[1] as FortuneAccessLocalStore;
    final wallet = _ref.read(walletBalancesProvider).valueOrNull;
    final tier = _ref.read(vipTierProvider);
    final jeton = wallet?.jeton ?? 0;
    final serverCredits = wallet?.fortuneAdCredits;
    final adCredits = serverCredits ?? store.adCredits;
    if (serverCredits != null && serverCredits != store.adCredits) {
      await store.setAdCredits(serverCredits);
    }
    final isPremium = _isPremiumUnlimited(config, tier, wallet?.membership);
    return FortuneAccessState(
      config: config,
      adCredits: adCredits,
      adsWatchedToday: store.adsWatchedToday,
      jetonBalance: jeton,
      isPremiumUnlimited: isPremium,
    );
  }

  bool _isPremiumUnlimited(
    FortuneAccessConfig config,
    VipTier tier,
    String? membership,
  ) {
    if (!config.premiumUnlimited) return false;
    final hasMembership = (membership ?? '').trim().isNotEmpty &&
        membership!.toLowerCase() != 'basic';
    return hasMembership && tier.index >= VipTier.premium.index;
  }

  /// Fal açılmadan önce ödeme / hak tüketimi.
  Future<void> consumeGrant({
    required FortuneTypeEntity type,
    required FortuneAccessGrant grant,
  }) async {
    switch (grant.method) {
      case FortuneAccessMethod.premium:
        return;
      case FortuneAccessMethod.adCredit:
        final store = await _store();
        final ok = await store.consumeAdCredit();
        if (!ok) {
          throw StateError('Reklam fal hakkı bulunamadı.');
        }
        _ref.invalidate(fortuneAccessStateProvider);
        return;
      case FortuneAccessMethod.jeton:
        final config = await _ref.read(fortuneAccessConfigProvider.future);
        try {
          await _remote.consumeJetonAccess(
            slug: type.slug,
            jetonCost: grant.jetonCost > 0 ? grant.jetonCost : config.jetonCost,
          );
        } catch (_) {
          // Sunucu uç yoksa jeton düşümü fal POST'unda yapılır.
        }
        await _ref.read(walletBalancesProvider.notifier).refresh(force: true);
        _ref.invalidate(fortuneAccessStateProvider);
        return;
    }
  }

  /// Ödüllü reklam izlet, +N fal hakkı ver.
  Future<int> watchAdForCredit({required String slug}) async {
    final completed = await RewardedAdService.instance.show();
    if (!completed) {
      throw StateError('Reklam tamamlanmadı; fal hakkı verilmedi.');
    }
    return grantFortuneAdCreditAfterWatch(slug: slug);
  }

  /// Reklam zaten izlendiyse fal hakkı ver (çift reklam önlenir).
  Future<int> grantFortuneAdCreditAfterWatch({required String slug}) async {
    final config = await _ref.read(fortuneAccessConfigProvider.future);
    if (!config.adsEnabled) {
      throw StateError('Reklam ödülleri şu an kapalı.');
    }
    final store = await _store();
    if (store.adsWatchedToday >= config.dailyAdLimit) {
      throw StateError('Günlük reklam limitine ulaştınız.');
    }

    var earned = config.adCreditsPerAd;
    try {
      earned = await _remote.rewardFortuneAdCredit(slug: slug);
    } catch (_) {
      // API yoksa yerel hak ver.
    }

    await store.incrementAdsWatchedToday();
    final total = await store.addAdCredits(earned);
    _ref.invalidate(fortuneAccessStateProvider);
    return total;
  }

  String paymentMethodFor(FortuneAccessGrant grant) {
    return switch (grant.method) {
      FortuneAccessMethod.premium => 'premium',
      FortuneAccessMethod.adCredit => 'ad_credit',
      FortuneAccessMethod.jeton => 'jeton',
    };
  }
}
