import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/economy/presentation/providers/economy_providers.dart';
import '../../domain/fortune_access_config.dart';
import '../providers/fortune_access_providers.dart';

/// Fal açma seçenekleri — reklam hakkı / jeton / premium.
enum FortuneAccessChoice {
  useAdCredit,
  payJeton,
  payCfc,
  watchAdForCredit,
  cancel,
}

Future<FortuneAccessChoice?> showFortuneAccessSheet({
  required BuildContext context,
  required FortuneAccessState state,
  required String fortuneTitle,
}) {
  final container = ProviderScope.containerOf(context);
  return showModalBottomSheet<FortuneAccessChoice>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => UncontrolledProviderScope(
      container: container,
      child: _FortuneAccessSheetBody(
        state: state,
        fortuneTitle: fortuneTitle,
      ),
    ),
  );
}

class _FortuneAccessSheetBody extends ConsumerWidget {
  const _FortuneAccessSheetBody({
    required this.state,
    required this.fortuneTitle,
  });

  final FortuneAccessState state;
  final String fortuneTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cost = state.config.jetonCost;
    final hasCredits = state.hasAdCredits;
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');
    final cfcLabel = economyCurrencyLabel(ref, key: 'cfc');

    return SafeArea(
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
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else
              Text(
                'Fal bakmak için $cost $jetonLabel/$cfcLabel veya reklam izleyebilirsin.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 16),
            if (state.isPremiumUnlimited) ...[
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, FortuneAccessChoice.useAdCredit),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Sınırsız AI Fal'),
              ),
            ] else if (hasCredits) ...[
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, FortuneAccessChoice.useAdCredit),
                icon: const Icon(Icons.card_giftcard_rounded),
                label: Text('Fal Hakkını Kullan ($cost)'),
              ),
              const SizedBox(height: 10),
              if (state.hasEnoughJeton)
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, FortuneAccessChoice.payJeton),
                  icon: const Icon(Icons.toll_rounded),
                  label: Text('$cost $jetonLabel ile Hemen Bak'),
                ),
              if (state.hasEnoughCfc) ...[
                if (state.hasEnoughJeton) const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, FortuneAccessChoice.payCfc),
                  icon: const Icon(Icons.diamond_rounded),
                  label: Text('$cost $cfcLabel ile Hemen Bak'),
                ),
              ],
            ] else ...[
              if (state.hasEnoughJeton)
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, FortuneAccessChoice.payJeton),
                  icon: const Icon(Icons.toll_rounded),
                  label: Text('$cost $jetonLabel ile Hemen Bak'),
                ),
              if (state.hasEnoughCfc) ...[
                if (state.hasEnoughJeton) const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, FortuneAccessChoice.payCfc),
                  icon: const Icon(Icons.diamond_rounded),
                  label: Text('$cost $cfcLabel ile Hemen Bak'),
                ),
              ],
              if (!state.hasEnoughJeton && !state.hasEnoughCfc)
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, FortuneAccessChoice.payJeton),
                  icon: const Icon(Icons.toll_rounded),
                  label: Text('$cost $jetonLabel ile Hemen Bak'),
                ),
              if (state.config.adsEnabled && state.canWatchMoreAds) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, FortuneAccessChoice.watchAdForCredit),
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: Text('Reklam İzle (+10 $cfcLabel) ve Fal Aç'),
                ),
              ],
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, FortuneAccessChoice.cancel),
              child: const Text('Vazgeç'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<FortuneAccessChoice?> showInsufficientJetonSheet({
  required BuildContext context,
  required FortuneAccessConfig config,
  required bool canWatchAd,
}) {
  final container = ProviderScope.containerOf(context);
  return showModalBottomSheet<FortuneAccessChoice>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => UncontrolledProviderScope(
      container: container,
      child: _InsufficientJetonSheetBody(
        config: config,
        canWatchAd: canWatchAd,
      ),
    ),
  );
}

class _InsufficientJetonSheetBody extends ConsumerWidget {
  const _InsufficientJetonSheetBody({
    required this.config,
    required this.canWatchAd,
  });

  final FortuneAccessConfig config;
  final bool canWatchAd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jetonLabel = economyCurrencyLabel(ref, key: 'jeton');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Yetersiz $jetonLabel',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Fal bakabilmek için ${config.jetonCost} $jetonLabel gerekli.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            if (config.adsEnabled && canWatchAd)
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(context, FortuneAccessChoice.watchAdForCredit),
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('Reklam İzle (1 Fal Hakkı Kazan)'),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/jeton-store');
              },
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text(economyJetonPurchasePageTitle(ref)),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push('/profile/growth');
              },
              icon: const Icon(Icons.task_alt_rounded),
              label: const Text('Görevler'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context, FortuneAccessChoice.cancel),
              child: const Text('Vazgeç'),
            ),
          ],
        ),
      ),
    );
  }
}
