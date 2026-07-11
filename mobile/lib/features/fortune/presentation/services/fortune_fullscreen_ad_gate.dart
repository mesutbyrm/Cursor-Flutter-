import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/cfc_reward_overlay.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/services/rewarded_ad_service.dart';

/// Fal açılmadan önce tam ekran reklam — jeton ile ödeyenlere gösterilmez.
class FortuneFullscreenAdGate {
  FortuneFullscreenAdGate._();

  static Future<bool> showBeforeFortune({
    required BuildContext context,
    required bool paidWithJeton,
    WidgetRef? ref,
    int fallbackCfcAmount = 10,
  }) async {
    if (paidWithJeton) return true;

    final watched = await RewardedAdService.instance.show();
    if (!context.mounted) return watched;

    if (!watched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reklam tamamlanmadan fal açılamaz.'),
        ),
      );
      return false;
    }

    if (ref != null) {
      await _celebrateCfcReward(
        context: context,
        ref: ref,
        fallbackAmount: fallbackCfcAmount,
      );
    }
    return true;
  }

  static Future<void> _celebrateCfcReward({
    required BuildContext context,
    required WidgetRef ref,
    required int fallbackAmount,
  }) async {
    var amount = fallbackAmount;
    try {
      amount = await ref.read(watchAdCreditProvider.future);
      if (amount <= 0) amount = fallbackAmount;
      ref.invalidate(walletBalancesProvider);
    } catch (_) {}

    if (context.mounted) {
      await CfcRewardOverlay.show(context, amount: amount);
    }
  }
}
