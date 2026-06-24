import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/fortune_access_config.dart';
import '../providers/fortune_access_providers.dart';

/// Fal açma seçenekleri — reklam hakkı / jeton / premium.
enum FortuneAccessChoice {
  useAdCredit,
  payJeton,
  watchAdForCredit,
  cancel,
}

Future<FortuneAccessChoice?> showFortuneAccessSheet({
  required BuildContext context,
  required FortuneAccessState state,
  required String fortuneTitle,
}) {
  final cost = state.config.jetonCost;
  final hasCredits = state.hasAdCredits;

  return showModalBottomSheet<FortuneAccessChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              fortuneTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            if (state.isPremiumUnlimited)
              const Text('Premium üyelik: sınırsız AI fal')
            else if (hasCredits)
              Text(
                'Reklamdan kazanılan ${state.adCredits} fal hakkın var.',
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
              )
            else
              Text(
                'Fal bakmak için $cost jeton veya reklam izleyebilirsin.',
                style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 16),
            if (state.isPremiumUnlimited) ...[
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, FortuneAccessChoice.useAdCredit),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Sınırsız AI Fal'),
              ),
            ] else if (hasCredits) ...[
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, FortuneAccessChoice.useAdCredit),
                icon: const Icon(Icons.card_giftcard_rounded),
                label: const Text('Reklam İzleyerek Ücretsiz Fal Bak'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx, FortuneAccessChoice.payJeton),
                icon: const Icon(Icons.toll_rounded),
                label: Text('$cost Jeton ile Hemen Bak'),
              ),
            ] else ...[
              FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, FortuneAccessChoice.payJeton),
                icon: const Icon(Icons.toll_rounded),
                label: Text('$cost Jeton ile Hemen Bak'),
              ),
              if (state.config.adsEnabled && state.canWatchMoreAds) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pop(ctx, FortuneAccessChoice.watchAdForCredit),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: const Text('Reklam İzle ve 1 Fal Hakkı Kazan'),
                ),
              ],
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx, FortuneAccessChoice.cancel),
              child: const Text('Vazgeç'),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<FortuneAccessChoice?> showInsufficientJetonSheet({
  required BuildContext context,
  required FortuneAccessConfig config,
  required bool canWatchAd,
}) {
  return showModalBottomSheet<FortuneAccessChoice>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Yetersiz jeton',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Fal bakabilmek için ${config.jetonCost} jeton gerekli.',
              style: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (config.adsEnabled && canWatchAd)
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(ctx, FortuneAccessChoice.watchAdForCredit),
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Reklam İzle (1 Fal Hakkı Kazan)'),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/jeton-store');
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Jeton Satın Al'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx, FortuneAccessChoice.cancel),
              child: const Text('Vazgeç'),
            ),
          ],
        ),
      ),
    ),
  );
}
