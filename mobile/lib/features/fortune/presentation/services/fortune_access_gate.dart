import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../../domain/fortune_access_config.dart';
import '../providers/fortune_access_providers.dart';
import '../widgets/fortune_access_sheet.dart';
import 'fortune_access_service.dart';

/// Fal açmadan önce erişim kapısı — premium / reklam / jeton.
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
          final ok = await _watchAdAndGrant(context, ref, service, type.slug);
          if (!ok) return null;
          state = await ref.read(fortuneAccessStateProvider.future);
          if (state.hasAdCredits) {
            return FortuneAccessGrant(
              method: FortuneAccessMethod.adCredit,
              jetonCost: state.config.jetonCost,
            );
          }
        }
        continue;
      }

      if (choice == FortuneAccessChoice.watchAdForCredit) {
        final ok = await _watchAdAndGrant(context, ref, service, type.slug);
        if (!ok) return null;
        state = await ref.read(fortuneAccessStateProvider.future);
        if (state.hasAdCredits) {
          return FortuneAccessGrant(
            method: FortuneAccessMethod.adCredit,
            jetonCost: state.config.jetonCost,
          );
        }
        continue;
      }
    }
    return null;
  }

  static Future<bool> _watchAdAndGrant(
    BuildContext context,
    WidgetRef ref,
    FortuneAccessService service,
    String slug,
  ) async {
    try {
      await service.watchAdForCredit(slug: slug);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('+1 fal hakkı kazandınız!')),
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
      return false;
    }
  }
}
