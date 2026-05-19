import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../constants/premium_home_layout.dart';
import '../../models/premium_quick_action.dart';
import '../../theme/premium_live_theme.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key, required this.actions});

  final List<PremiumQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 520;
        final children = List.generate(actions.length, (i) {
          final a = actions[i];
          return _QuickActionTile(action: a, index: i)
              .animate()
              .fadeIn(
                delay: PremiumHomeLayout.stagger * i,
                duration: PremiumHomeLayout.animMedium,
              )
              .slideY(
                begin: 0.12,
                end: 0,
                curve: Curves.easeOutCubic,
                delay: PremiumHomeLayout.stagger * i,
              );
        });
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                Expanded(child: children[i]),
                if (i != children.length - 1) SizedBox(width: 1.4.w),
              ],
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: children[0]),
                SizedBox(width: 2.w),
                Expanded(child: children[1]),
              ],
            ),
            SizedBox(height: 1.4.h),
            Row(
              children: [
                Expanded(child: children[2]),
                SizedBox(width: 2.w),
                Expanded(child: children[3]),
              ],
            ),
            SizedBox(height: 1.4.h),
            SizedBox(width: double.infinity, child: children[4]),
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
        borderRadius: BorderRadius.circular(PremiumHomeLayout.glassRadius),
        onTap: () {
          if (action.title.contains('Sesli')) {
            context.push('/voice-rooms');
          } else if (action.title.contains('Canlı')) {
            context.go('/live');
          }
        },
        child: SizedBox(
          height: 19.h.clamp(112.0, 168.0),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PremiumHomeLayout.glassRadius),
              gradient: g,
              boxShadow: [
                BoxShadow(
                  color: PremiumLiveTheme.neonPink.withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(PremiumHomeLayout.glassRadius),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.22),
                      Colors.white.withValues(alpha: 0.04),
                    ],
                  ),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
                ),
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.6.h),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(action.icon, color: Colors.white, size: 30.sp),
                    SizedBox(height: 1.h),
                    Text(
                      action.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
