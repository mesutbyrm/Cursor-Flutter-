import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/responsive/responsive_layout.dart';
import '../../../../core/widgets/discover/discover_icon_button.dart';
import '../providers/fortune_api_providers.dart';
import '../widgets/fortune_glass_card.dart';
import '../widgets/fortune_mystic_background.dart';

/// `GET /api/user/fortunes/{id}` — fal geçmişi detayı.
class FortuneDetailPage extends ConsumerWidget {
  const FortuneDetailPage({super.key, required this.fortuneId});

  final String fortuneId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(fortuneDetailProvider(fortuneId));
    final top = MediaQuery.paddingOf(context).top;
    final palette = context.palette;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: FortuneMysticBackground(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, top + 4, 12, 8),
              child: Row(
                children: [
                  DiscoverIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      'Fal detayı',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: detail.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: ResponsiveLayout.pagePadding(context),
                    child: Text(ApiException.userMessage(e)),
                  ),
                ),
                data: (f) {
                  final when = f.createdAt != null
                      ? DateFormat('d MMMM yyyy, HH:mm', 'tr')
                          .format(f.createdAt!.toLocal())
                      : null;
                  return SingleChildScrollView(
                    padding: ResponsiveLayout.pagePadding(context).copyWith(
                      bottom: 32,
                    ),
                    child: FortuneGlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            f.displayTitle,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: palette.textPrimary,
                            ),
                          ),
                          if (when != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              when,
                              style: TextStyle(
                                color: palette.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (f.question != null &&
                              f.question!.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Soru',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: palette.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              f.question!,
                              style: TextStyle(
                                height: 1.45,
                                color: palette.textPrimary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            'Yorum',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: palette.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            f.displayBody,
                            style: TextStyle(
                              height: 1.5,
                              fontSize: 16,
                              color: palette.textPrimary,
                            ),
                          ),
                          if (f.luckyNumber != null || f.luckyColor != null) ...[
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                if (f.luckyNumber != null)
                                  _Chip(
                                    label: 'Şanslı sayı: ${f.luckyNumber}',
                                  ),
                                if (f.luckyNumber != null && f.luckyColor != null)
                                  const SizedBox(width: 8),
                                if (f.luckyColor != null)
                                  _Chip(label: 'Renk: ${f.luckyColor}'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.glassBorder),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: c.onSurface,
          fontSize: 13,
        ),
      ),
    );
  }
}
