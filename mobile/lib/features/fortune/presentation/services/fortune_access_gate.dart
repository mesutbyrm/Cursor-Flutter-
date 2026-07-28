import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/fortune_type_entity.dart';
import '../../domain/fortune_access_config.dart';
import '../providers/fortune_access_providers.dart';
import '../widgets/fortune_access_sheet.dart';
import 'ad_reward_celebration.dart';

/// Fal açmadan önce erişim kapısı — premium / reklam / jeton / CFC.
class FortuneAccessGate {
  FortuneAccessGate._();

  /// Misafir veya günlük fal için `null` (ücretsiz akış).
  /// Oturumlu AI fal için grant döner; vazgeçte `null`.
  static Future<FortuneAccessGrant?> request({
    required BuildContext context,
    required WidgetRef ref,
    required FortuneTypeEntity type,
    required bool isAuthenticated,
  }) async {
    final service = ref.read(fortuneAccessServiceProvider);
    if (!service.isGateRequired(type, isAuthenticated: isAuthenticated)) {
      return null;
    }

    var state = await ref.read(fortuneAccessStateProvider.future);
    if (!context.mounted) return null;

    if (state.isPremiumUnlimited) {
      return const FortuneAccessGrant(method: FortuneAccessMethod.premium);
    }

    while (context.mounted) {
      final choice = await showFortuneAccessSheet(
        context: context,
        state: state,
        fortuneTitle: type.title,
      );
      if (!context.mounted) return null;
      if (choice == null || choice == FortuneAccessChoice.cancel) return null;

      if (choice == FortuneAccessChoice.useAdCredit && state.hasAdCredits) {
        return FortuneAccessGrant(
          method: FortuneAccessMethod.adCredit,
          jetonCost: state.config.jetonCost,
        );
      }

      if (choice == FortuneAccessChoice.payCfc && state.hasEnoughCfc) {
        return FortuneAccessGrant(
          method: FortuneAccessMethod.cfc,
          jetonCost: state.config.jetonCost,
        );
      }

      if (choice == FortuneAccessChoice.payJeton) {
        if (state.hasEnoughJeton) {
          return FortuneAccessGrant(
            method: FortuneAccessMethod.jeton,
            jetonCost: state.config.jetonCost,
          );
        }
        final insufficient = await showInsufficientJetonSheet(
          context: context,
          config: state.config,
          canWatchAd: state.canWatchMoreAds,
        );
        if (!context.mounted) return null;
        if (insufficient == FortuneAccessChoice.watchAdForCredit) {
          final grant = await _watchAdForFortuneUnlock(
            context,
            ref,
            state.config.jetonCost,
          );
          if (grant != null) return grant;
        }
        continue;
      }

      if (choice == FortuneAccessChoice.watchAdForCredit) {
        final grant = await _watchAdForFortuneUnlock(
          context,
          ref,
          state.config.jetonCost,
        );
        if (grant != null) return grant;
        continue;
      }
    }
    return null;
  }

  /// Reklam izle → +10 CFC → falı otomatik aç (tek reklam).
  static Future<FortuneAccessGrant?> _watchAdForFortuneUnlock(
    BuildContext context,
    WidgetRef ref,
    int cost,
  ) async {
    final ok = await AdRewardCelebration.watchAndCelebrate(
      context: context,
      ref: ref,
      fallbackAmount: 10,
    );
    if (!ok || !context.mounted) return null;

    final state = await ref.read(fortuneAccessStateProvider.future);
    if (state.hasEnoughCfc) {
      return FortuneAccessGrant(method: FortuneAccessMethod.cfc, jetonCost: cost);
    }
    if (state.hasEnoughJeton) {
      return FortuneAccessGrant(method: FortuneAccessMethod.jeton, jetonCost: cost);
    }
    return const FortuneAccessGrant(method: FortuneAccessMethod.adUnlocked);
  }
}
