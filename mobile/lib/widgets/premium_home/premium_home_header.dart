import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../theme/premium_live_theme.dart';
import 'neon_glass_panel.dart';

class PremiumHomeHeader extends StatelessWidget {
  const PremiumHomeHeader({
    super.key,
    required this.displayName,
    this.tokenBalance = 12540,
    this.onNotifications,
  });

  final String displayName;
  final int tokenBalance;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(3.w, 0, 3.w, 1.2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarGlow()
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.92, 0.92), curve: Curves.easeOutCubic),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hoş geldin',
                  style: PremiumLiveTheme.bodyMuted(context),
                )
                    .animate()
                    .fadeIn(delay: 80.ms)
                    .slideX(begin: -0.04, end: 0, curve: Curves.easeOut),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: PremiumLiveTheme.displaySm(context).copyWith(
                          fontSize: 19.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 1.w),
                    Icon(
                      Icons.verified_rounded,
                      color: PremiumLiveTheme.neonPurple,
                      size: 20.sp,
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(delay: 120.ms)
                    .slideX(begin: -0.06, end: 0, curve: Curves.easeOut),
              ],
            ),
          ),
          NeonGlassPanel(
            borderRadius: 22,
            padding: EdgeInsets.symmetric(horizontal: 2.8.w, vertical: 0.7.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.diamond_rounded,
                    color: PremiumLiveTheme.neonBlue, size: 17.sp),
                SizedBox(width: 1.w),
                Text(
                  _formatTokens(tokenBalance),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5.sp,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(delay: 160.ms)
              .moveY(begin: 6, end: 0, curve: Curves.easeOut),
          SizedBox(width: 2.w),
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onNotifications ?? () => context.push('/notifications'),
              child: NeonGlassPanel(
                borderRadius: 999,
                padding: EdgeInsets.all(2.w),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.notifications_none_rounded,
                        color: Colors.white, size: 22.sp),
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms)
              .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),
        ],
      ),
    );
  }

  static String _formatTokens(int n) {
    return NumberFormat.decimalPattern('tr_TR').format(n);
  }
}

class _AvatarGlow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15.w,
      height: 15.w,
      constraints: const BoxConstraints(maxWidth: 58, maxHeight: 58),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            PremiumLiveTheme.neonPink.withValues(alpha: 0.9),
            PremiumLiveTheme.neonPurple.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: PremiumLiveTheme.neonPink.withValues(alpha: 0.45),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.2),
      child: ClipOval(
        child: Image.network(
          'https://i.pravatar.cc/200?u=cemre_premium',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => ColoredBox(
            color: PremiumLiveTheme.deepPurple,
            child: Icon(Icons.person_rounded, color: Colors.white, size: 28.sp),
          ),
        ),
      ),
    );
  }
}
