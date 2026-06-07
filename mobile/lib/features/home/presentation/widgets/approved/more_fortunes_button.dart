import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/home_approved_design.dart';

/// Onaylı mockup — "+6 Daha Fazla Fal" tam genişlik düğme.
class MoreFortunesButton extends StatelessWidget {
  const MoreFortunesButton({super.key});

  @override
  Widget build(BuildContext context) {
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '✨ +6 Daha Fazla Fal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: HomeApprovedDesign.textPrimary,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
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
