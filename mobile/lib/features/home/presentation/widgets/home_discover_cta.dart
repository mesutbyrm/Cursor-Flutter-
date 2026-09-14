import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/cds_button.dart';
import '../../../../core/design_system/cds_spacing.dart';
import '../theme/home_approved_design.dart';

/// Keşfet — Tanış & Kaynaş tek CTA (ana sayfada ayrı büyük section yok).
class HomeDiscoverCta extends StatelessWidget {
  const HomeDiscoverCta({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        HomeApprovedDesign.hPad,
        CdsSpacing.sm,
        HomeApprovedDesign.hPad,
        CdsSpacing.lg,
      ),
      child: CdsButton(
        label: 'Tanış & Kaynaş — keşfet',
        icon: Icons.explore_rounded,
        variant: CdsButtonVariant.secondary,
        onPressed: () => context.push('/social/tanis-kaynas'),
      ),
    );
  }
}
