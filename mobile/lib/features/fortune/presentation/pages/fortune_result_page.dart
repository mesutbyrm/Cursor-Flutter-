import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/discover/discover_icon_button.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../widgets/fortune_glass_card.dart';
import '../widgets/fortune_mystic_background.dart';
import '../widgets/fortune_share_sheet.dart';

/// Fal sonucu — özet, detay, şanslı sayı, paylaş.
class FortuneResultPage extends StatelessWidget {
  const FortuneResultPage({super.key, required this.result});

  final FortuneReadingResult result;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final type = result.type;

    return Scaffold(
      backgroundColor: AppColors.background,
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
                      '${type.title} Sonucu',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.ios_share_rounded),
                    color: AppColors.textPrimary,
                    onPressed: () => showFortuneShareSheet(context, result),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FortuneGlassCard(
                      accent: type.accent,
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          Text(type.emoji, style: const TextStyle(fontSize: 56)),
                          const SizedBox(height: 16),
                          Text(
                            result.summary,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FortuneGlassCard(
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        result.detail,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.5,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (result.luckyNumber != null ||
                        result.luckyColor != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (result.luckyNumber != null)
                            Expanded(
                              child: _LuckyChip(
                                label: 'Şanslı sayı',
                                value: '${result.luckyNumber}',
                                color: type.accent,
                              ),
                            ),
                          if (result.luckyNumber != null &&
                              result.luckyColor != null)
                            const SizedBox(width: 12),
                          if (result.luckyColor != null)
                            Expanded(
                              child: _LuckyChip(
                                label: 'Şanslı renk',
                                value: result.luckyColor!,
                                color: AppColors.accentCyan,
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => showFortuneShareSheet(context, result),
                      icon: const Icon(Icons.share_rounded),
                      label: const Text('Paylaş'),
                      style: FilledButton.styleFrom(
                        backgroundColor: type.accent,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => context.go('/fortune'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Diğer fallara göz at'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LuckyChip extends StatelessWidget {
  const _LuckyChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        color: color.withValues(alpha: 0.12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.9),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
