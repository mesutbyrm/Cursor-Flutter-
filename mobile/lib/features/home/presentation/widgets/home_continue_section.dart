import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/cds_card.dart';
import '../../../../core/design_system/cds_colors.dart';
import '../../../../core/design_system/cds_spacing.dart';
import '../../../../core/design_system/cds_typography.dart';
import '../theme/home_approved_design.dart';

/// Kişiselleştirilmiş devam et — canlı, ses, fal.
class HomeContinueSection extends StatelessWidget {
  const HomeContinueSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeApprovedDesign.hPad,
        CdsSpacing.sm,
        HomeApprovedDesign.hPad,
        CdsSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Devam et', style: CdsTypography.title(context)),
          const SizedBox(height: CdsSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ContinueTile(
                  icon: Icons.videocam_rounded,
                  label: 'Canlı',
                  color: CdsColors.liveHot,
                  onTap: () => context.go('/live'),
                ),
              ),
              const SizedBox(width: CdsSpacing.sm),
              Expanded(
                child: _ContinueTile(
                  icon: Icons.mic_rounded,
                  label: 'Sesli oda',
                  color: CdsColors.accentCyan,
                  onTap: () => context.push('/voice-rooms'),
                ),
              ),
              const SizedBox(width: CdsSpacing.sm),
              Expanded(
                child: _ContinueTile(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Fal',
                  color: CdsColors.fortuneMystic,
                  onTap: () => context.go('/fortune'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContinueTile extends StatelessWidget {
  const _ContinueTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CdsCard(
      variant: CdsCardVariant.interactive,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        vertical: CdsSpacing.md,
        horizontal: CdsSpacing.sm,
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: CdsSpacing.xs),
          Text(
            label,
            style: CdsTypography.label(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
