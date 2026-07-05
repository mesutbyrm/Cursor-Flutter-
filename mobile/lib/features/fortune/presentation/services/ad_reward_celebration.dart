import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/cfc_reward_overlay.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/services/rewarded_ad_service.dart';
import '../providers/fortune_access_providers.dart';

/// Ödüllü reklam izlet → sunucuya bildir → CFC ödül overlay göster.
class AdRewardCelebration {
  AdRewardCelebration._();

  static Future<bool> watchAndCelebrate({
    required BuildContext context,
    required WidgetRef ref,
    int fallbackAmount = 10,
    Future<void> Function()? onAdWatched,
  }) async {
    final watched = await RewardedAdService.instance.show();
    if (!context.mounted) return false;
    if (!watched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reklam tamamlanmadı; ödül verilmedi.')),
      );
      return false;
    }

    if (onAdWatched != null) {
      try {
        await onAdWatched();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ApiException.userMessage(e))),
          );
        }
        return false;
      }
    }

    var amount = fallbackAmount;
    try {
      amount = await ref.read(watchAdCreditProvider.future);
      if (amount <= 0) amount = fallbackAmount;
      ref.invalidate(walletBalancesProvider);
      ref.invalidate(fortuneAccessStateProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    }

    if (context.mounted) {
      await CfcRewardOverlay.show(context, amount: amount);
    }
    return true;
  }
}
