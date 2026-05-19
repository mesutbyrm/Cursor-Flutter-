import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../constants/premium_home_layout.dart';
import '../../models/premium_quick_action.dart';
import '../../theme/premium_live_theme.dart';

/// Görseldeki gibi tek yatay sıra: 5 kare gradient düğme.
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key, required this.actions});

  final List<PremiumQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 7.0;
        final n = actions.length;
        final tileW = (c.maxWidth - gap * (n - 1)) / n;
        final tileH = tileW.clamp(86.0, 108.0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) SizedBox(width: gap),
              SizedBox(
                width: tileW,
                height: tileH,
                child: _QuickActionTile(
                  action: actions[i],
                  index: i,
                )
                    .animate()
                    .fadeIn(
                      delay: PremiumHomeLayout.stagger * i,
                      duration: PremiumHomeLayout.animMedium,
                    )
                    .slideY(
                      begin: 0.1,
                      end: 0,
                      curve: Curves.easeOutCubic,
                      delay: PremiumHomeLayout.stagger * i,
                    ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action, required this.index});

  final PremiumQuickAction action;
  final int index;

  @override
  Widget build(BuildContext context) {
    final g = PremiumLiveTheme.actionGradient(action.gradientIndex);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (action.title.contains('Sesli')) {
            context.push('/voice-rooms');
          } else if (action.title.contains('Canlı')) {
            context.go('/live');
          }
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: g,
            boxShadow: [
              BoxShadow(
                color: PremiumLiveTheme.neonPink.withValues(alpha: 0.2),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.24),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              padding: EdgeInsets.symmetric(horizontal: 1.2.w, vertical: 1.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon, color: Colors.white, size: 26.sp),
                  SizedBox(height: 0.6.h),
                  Text(
                    action.title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.2.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
