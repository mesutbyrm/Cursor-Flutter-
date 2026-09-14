import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/cds_card.dart';
import '../../../../core/design_system/cds_colors.dart';
import '../../../../core/design_system/cds_spacing.dart';
import '../../../../core/design_system/cds_typography.dart';
import '../theme/home_approved_design.dart';
import 'approved/fortune_section.dart';

/// Fal vitrin + Gold üyelik tek odak alanı.
class HomeFortuneGoldSpotlight extends StatelessWidget {
  const HomeFortuneGoldSpotlight({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const FortuneSection(),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            HomeApprovedDesign.hPad,
            0,
            HomeApprovedDesign.hPad,
            CdsSpacing.md,
          ),
          child: CdsCard(
            variant: CdsCardVariant.glass,
            onTap: () => context.push('/premium-membership'),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: CdsColors.gold),
                const SizedBox(width: CdsSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gold üyelik',
                        style: CdsTypography.title(context),
                      ),
                      Text(
                        'Özel rozetler ve ayrıcalıklar',
                        style: CdsTypography.caption(context),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
