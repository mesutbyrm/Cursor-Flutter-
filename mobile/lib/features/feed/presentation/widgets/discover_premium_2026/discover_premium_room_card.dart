import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../../../core/ui/premium_2026/premium_motion.dart';
import 'discover_premium_visual.dart';
import '../../../domain/discover_category.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../voice_hub/presentation/widgets/premium_2026/voice_discover_2026.dart';

/// Neon glow sesli oda kartı — yatay liste / grid.
class DiscoverPremiumRoomCard extends StatefulWidget {
  const DiscoverPremiumRoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.width = 168,
    this.compact = false,
  });

  final VoiceRoomEntity room;
  final VoidCallback onTap;
  final double width;
  final bool compact;

  @override
  State<DiscoverPremiumRoomCard> createState() =>
      _DiscoverPremiumRoomCardState();
}

class _DiscoverPremiumRoomCardState extends State<DiscoverPremiumRoomCard> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final online = widget.room.displayOnline;
    final bg = widget.room.backgroundImageUrl;
    final h = widget.compact ? 200.0 : 220.0;
    final isVip = matchesDiscoverCategory(widget.room, 'vip');

    return RepaintBoundary(
      child: GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: PremiumMotion.fast,
        curve: PremiumMotion.spring,
        child: AnimatedContainer(
          duration: PremiumMotion.medium,
          width: widget.width,
          height: h,
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
            boxShadow: DiscoverPremiumVisual.cardGlow(pressed: _pressed),
          ),
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (bg != null && bg.isNotEmpty)
                  CachedNetworkImage(imageUrl: bg, fit: BoxFit.cover)
                else
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4C1D95), Color(0xFF1E1033)],
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  right: 10,
                  child: Row(
                    children: [
                      _OnlinePill(count: online),
                      const Spacer(),
                      if (isVip) const _VipBadge(),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.room.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Colors.white,
                          height: 1.15,
                        ),
                      ),
                      if (widget.room.ownerName != null &&
                          widget.room.ownerName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.room.ownerName!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _AvatarStrip(avatars: widget.room.recentUserAvatars),
                    ],
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

class _OnlinePill extends StatelessWidget {
  const _OnlinePill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemeColors.onlineGreen.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: count > 0
                  ? AppThemeColors.onlineGreen
                  : Colors.white.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(width: 5),
          Text(
            VoiceLiveHeader2026Format.count(count),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _VipBadge extends StatelessWidget {
  const _VipBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE082), Color(0xFFFF8F00)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'VIP',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: Color(0xFF3E2723),
        ),
      ),
    );
  }
}

class _AvatarStrip extends StatelessWidget {
  const _AvatarStrip({required this.avatars});

  final List<String> avatars;

  @override
  Widget build(BuildContext context) {
    final urls = avatars.where((u) => u.isNotEmpty).take(4).toList();
    if (urls.isEmpty) return const SizedBox(height: 22);

    return SizedBox(
      height: 22,
      child: Stack(
        children: [
          for (var i = 0; i < urls.length; i++)
            Positioned(
              left: i * 14.0,
              child: CircleAvatar(
                radius: 11,
                backgroundColor: const Color(0xFF1E1033),
                backgroundImage: CachedNetworkImageProvider(urls[i]),
              ),
            ),
        ],
      ),
    );
  }
}
