import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/push/push_notification_service.dart';
import '../../data/fortune_hub_preferences_store.dart';
import '../../providers/fortune_hub_providers.dart';
import '../premium_2026/fortune_browse_carousel.dart';
import '../premium_2026/fortune_similar_section.dart';
import '../premium_2026/premium_section_header.dart';
import 'ultra_fortune_liquid_surface.dart';
import 'ultra_fortune_tokens.dart';

/// Hub öneri carousel — son fal veya günlük fal slug'ına göre.
class UltraFortuneRecommendationsSection extends ConsumerWidget {
  const UltraFortuneRecommendationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(fortuneHubPreferencesStoreProvider);
    final slug = storeAsync.valueOrNull?.lastFortuneSlug ?? 'tarot';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FortuneSimilarSection(currentSlug: slug),
        const SizedBox(height: 8),
        FortuneBrowseCarousel(excludeSlug: slug),
      ],
    );
  }
}

/// Son açılan fal — hero altı CTA.
class UltraFortuneLastFortuneCta extends ConsumerWidget {
  const UltraFortuneLastFortuneCta({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(fortuneHubPreferencesStoreProvider).valueOrNull;
    final slug = store?.lastFortuneSlug;
    final title = store?.lastFortuneTitle;
    if (slug == null || slug.isEmpty || title == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: UltraFortuneLiquidSurface(
        onTap: () => context.push('/fortune/$slug'),
        borderRadius: BorderRadius.circular(18),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        goldAccent: true,
        child: Row(
          children: [
            Icon(
              Icons.replay_rounded,
              color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.95),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SON FALINA DEVAM',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: UltraFortuneTokens.metallicGold.withValues(alpha: 0.85),
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}

/// Günlük fal hatırlatıcı toggle.
class UltraFortuneDailyReminderTile extends ConsumerWidget {
  const UltraFortuneDailyReminderTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storeAsync = ref.watch(fortuneHubPreferencesStoreProvider);

    return storeAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (store) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: UltraFortuneLiquidSurface(
            borderRadius: BorderRadius.circular(16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Günlük fal hatırlatıcısı',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              subtitle: Text(
                'Her gün falına bakman için bildirim',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
              value: store.dailyReminderEnabled,
              activeThumbColor: UltraFortuneTokens.metallicGold,
              onChanged: (v) async {
                await store.setDailyReminderEnabled(v);
                await PushNotificationService.instance
                    .setDailyFortuneReminderEnabled(v);
                ref.invalidate(fortuneHubPreferencesStoreProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        v
                            ? 'Hatırlatıcı açıldı'
                            : 'Hatırlatıcı kapatıldı',
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );
      },
    );
  }
}
