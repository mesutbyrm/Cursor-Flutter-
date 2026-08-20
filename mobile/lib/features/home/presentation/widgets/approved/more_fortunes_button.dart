import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../fortune/presentation/data/fortune_catalog.dart';
import '../../theme/home_approved_design.dart';

/// Fal türleri hub'ına giden dinamik CTA.
class MoreFortunesButton extends StatelessWidget {
  const MoreFortunesButton({super.key});

  @override
  Widget build(BuildContext context) {
    final extraCount = FortuneCatalog.types.length;
    final label = extraCount > 0
        ? '✨ Tüm Fal Türleri ($extraCount+)'
        : '✨ Tüm Fal Türleri';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeApprovedDesign.hPad,
        8,
        HomeApprovedDesign.hPad,
        4,
      ),
      child: Material(
        color: HomeApprovedDesign.surface,
        borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
        child: InkWell(
          onTap: () => context.push('/fortune/types'),
          borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(HomeApprovedDesign.cardRadius),
              border: Border.all(color: HomeApprovedDesign.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: HomeApprovedDesign.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: HomeApprovedDesign.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
