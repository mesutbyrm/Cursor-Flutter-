import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/design_system/cds_skeleton.dart';
import '../../providers/fortune_api_providers.dart';
import '../../data/fortune_catalog.dart';
import '../premium_2026/premium_section_header.dart';
import '../premium_2026/fortune_premium_card.dart';
import 'ultra_fortune_state_panel.dart';
import 'ultra_fortune_tokens.dart';

/// Son 3 fal geçmişi — yatay premium şerit.
class UltraFortuneHistoryStrip extends ConsumerWidget {
  const UltraFortuneHistoryStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(fortuneHistoryProvider);

    return history.when(
      // Yüklenirken şeridin gerçek düzeni: başlık + 3 kart iskeleti.
      loading: () => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CdsSkeleton.box(width: 120, height: 14),
              const SizedBox(height: 10),
              SizedBox(
                height: 132,
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: CdsSkeleton.box(
                          width: double.infinity,
                          height: 132,
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: UltraFortuneStatePanel(
          icon: Icons.cloud_off_rounded,
          message: 'Son fallar yüklenemedi',
          actionLabel: 'Tekrar dene',
          onAction: () => ref.invalidate(fortuneHistoryProvider),
          height: 100,
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: UltraFortuneStatePanel(
              icon: Icons.history_rounded,
              message: 'Henüz fal geçmişi yok',
              actionLabel: 'Fal baktır',
              onAction: () => context.push('/fortune/tarot'),
              height: 100,
            ),
          );
        }
        final preview = items.take(3).toList();
        final cardH = 132.0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: PremiumSectionHeader(
                      title: 'SON FALLARIN',
                      icon: Icons.history_rounded,
                      iconColor: UltraFortuneTokens.softLilac,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/favorites'),
                    child: Text(
                      'Tümü >',
                      style: TextStyle(
                        color: UltraFortuneTokens.softLilac.withValues(
                          alpha: 0.95,
                        ),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: cardH,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: preview.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final item = preview[i];
                    final slug = item.slug ?? '';
                    final catalog = FortuneCatalog.bySlug(slug);
                    final title = catalog?.title ?? item.displayTitle;
                    final accent =
                        catalog?.accent ?? UltraFortuneTokens.electricPurple;
                    return SizedBox(
                      width: 148,
                      child: FortunePremiumCard(
                        slug: slug.isNotEmpty ? slug : 'tarot',
                        title: title,
                        subtitle: _shortBody(item.displayBody),
                        accent: accent,
                        compact: true,
                        showEmojiInTitle: false,
                        height: cardH,
                        width: 148,
                        onTap: () {
                          if (slug.isNotEmpty) {
                            context.push('/fortune/$slug');
                          } else {
                            context.push('/favorites');
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String? _shortBody(String body) {
    final t = body.trim();
    if (t.isEmpty) return null;
    if (t.length <= 48) return t;
    return '${t.substring(0, 45)}…';
  }
}
