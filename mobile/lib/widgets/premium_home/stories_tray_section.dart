import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../models/premium_story_tray_item.dart';
import '../../theme/premium_live_theme.dart';

/// Mockup’taki üst yatay hikâye / yayıncı halkaları.
class StoriesTraySection extends StatelessWidget {
  const StoriesTraySection({super.key, required this.items});

  final List<PremiumStoryTrayItem> items;

  @override
  Widget build(BuildContext context) {
    final ring = 19.w.clamp(64.0, 76.0);
    final avatarSize = (ring - 9.4).clamp(44.0, 200.0);

    return SizedBox(
      height: ring + 4.2.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 1.w),
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(width: 3.2.w),
        itemBuilder: (context, i) {
          final s = items[i];
          return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StoryRing(
                    item: s,
                    ring: ring,
                    avatarSize: avatarSize,
                    index: i,
                  ),
                  SizedBox(height: 0.55.h),
                  SizedBox(
                    width: ring + 8,
                    child: Text(
                      s.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 9.5.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ),
                ],
              )
              .animate()
              .fadeIn(delay: (40 * i).ms, duration: 380.ms)
              .slideX(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
        },
      ),
    );
  }
}

class _StoryRing extends StatelessWidget {
  const _StoryRing({
    required this.item,
    required this.ring,
    required this.avatarSize,
    required this.index,
  });

  final PremiumStoryTrayItem item;
  final double ring;
  final double avatarSize;
  final int index;

  @override
  Widget build(BuildContext context) {
    final gradient = item.isAddStory
        ? const LinearGradient(colors: [Color(0xFF4A4A4A), Color(0xFF2A2A2A)])
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: item.hasNew || item.isLive
                ? [
                    PremiumLiveTheme.neonPink,
                    PremiumLiveTheme.neonPurple,
                    PremiumLiveTheme.neonBlue,
                  ]
                : [
                    Colors.white.withValues(alpha: 0.35),
                    Colors.white.withValues(alpha: 0.14),
                  ],
          );

    return SizedBox(
      width: ring,
      height: ring,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: ring,
            height: ring,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
              boxShadow: item.isAddStory
                  ? null
                  : [
                      BoxShadow(
                        color: PremiumLiveTheme.neonPink.withValues(
                          alpha: 0.22,
                        ),
                        blurRadius: 14,
                        spreadRadius: 0,
                      ),
                    ],
            ),
            padding: const EdgeInsets.all(2.5),
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF0D0B14),
              ),
              padding: const EdgeInsets.all(2.2),
              child: ClipOval(
                child: item.isAddStory
                    ? ColoredBox(
                        color: PremiumLiveTheme.deepPurple,
                        child: Icon(
                          Icons.add_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 28.sp,
                        ),
                      )
                    : SizedBox(
                        width: avatarSize,
                        height: avatarSize,
                        child: CachedNetworkImage(
                          imageUrl: item.avatarUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              ColoredBox(color: PremiumLiveTheme.cosmicPurple),
                          errorWidget: (_, __, ___) => ColoredBox(
                            color: PremiumLiveTheme.cosmicPurple,
                            child: Icon(
                              Icons.person_rounded,
                              color: Colors.white54,
                              size: 22.sp,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          if (item.isLive)
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF0D0B14),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  'CANLI',
                  style: GoogleFonts.montserrat(
                    fontSize: 7.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
