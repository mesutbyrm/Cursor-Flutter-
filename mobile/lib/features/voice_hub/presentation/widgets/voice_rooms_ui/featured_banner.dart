import 'package:flutter/material.dart';

import '../../performance/voice_rooms_perf.dart';
import 'voice_rooms_mock_data.dart';
import 'voice_rooms_svg_icons.dart';
import 'voice_rooms_ui_tokens.dart';
import 'voice_rooms_hero.dart';

class FeaturedBanner extends StatelessWidget {
  const FeaturedBanner({super.key, required this.items});

  final List<FeaturedRoomItem> items;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width >= 700 ? (width - 48) / 2 : (width - 40) / 2;

    return SizedBox(
      height: 148,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        scrollCacheExtent: VoiceRoomsPerf.scrollCacheExtent,
        padding: const EdgeInsets.symmetric(
          horizontal: VoiceRoomsUiTokens.padScreenH,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: EdgeInsets.only(
              right: index == items.length - 1
                  ? 0
                  : VoiceRoomsUiTokens.gapMd,
            ),
            child: RepaintBoundary(
              child: _FeaturedCard(
                item: item,
                width: cardWidth.clamp(160, 280),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.item, required this.width});

  final FeaturedRoomItem item;
  final double width;

  @override
  Widget build(BuildContext context) {
    return VoiceRoomsHero(
      tag: 'featured_${item.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusLg),
          splashColor: item.glowColor.withValues(alpha: 0.2),
          child: Container(
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusLg),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: item.gradient,
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
              boxShadow: VoiceRoomsUiTokens.glowShadow(item.glowColor, blur: 28),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -12,
                  bottom: -16,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: item.glowColor.withValues(alpha: 0.45),
                          blurRadius: 40,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: VoiceRoomsSvgIcons.icon(
                        item.iconKey,
                        size: 40,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(
                            VoiceRoomsUiTokens.radiusXs,
                          ),
                        ),
                        child: Text(
                          item.badge,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          VoiceRoomsSvgIcons.icon(
                            item.iconKey,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
