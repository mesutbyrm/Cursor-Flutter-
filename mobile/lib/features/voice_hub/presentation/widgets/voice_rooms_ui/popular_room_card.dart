import 'package:flutter/material.dart';

import 'voice_rooms_mock_data.dart';
import 'voice_rooms_svg_icons.dart';
import 'voice_rooms_ui_tokens.dart';

/// Popüler oda kartı — carousel ve grid için yeniden kullanılabilir.
class PopularRoomCard extends StatelessWidget {
  const PopularRoomCard({
    super.key,
    required this.room,
    this.width = 168,
    this.onTap,
  });

  final PopularRoomItem room;
  final double width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'popular_${room.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusLg),
          splashColor: room.themeColor.withValues(alpha: 0.25),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: width,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusLg),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  room.themeColor.withValues(alpha: 0.55),
                  const Color(0xFF141414),
                ],
              ),
              border: Border.all(
                color: room.themeColor.withValues(alpha: 0.35),
              ),
              boxShadow: VoiceRoomsUiTokens.glowShadow(room.themeColor, blur: 18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _RankBadge(rank: room.rank, color: room.themeColor),
                      const Spacer(),
                      _ViewerPill(viewers: room.viewers),
                      const SizedBox(width: 6),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: VoiceRoomsSvgIcons.icon(
                            room.iconKey,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _AvatarStack(colors: room.avatarColors),
                  const SizedBox(height: 10),
                  Text(
                    room.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    room.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: room.tags
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                VoiceRoomsUiTokens.radiusPill,
                              ),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _MiniAvatarRow(colors: room.avatarColors),
                      const SizedBox(width: 6),
                      Text(
                        '+${room.participantCount}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.color});

  final int rank;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: VoiceRoomsUiTokens.glowShadow(color, blur: 10),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ViewerPill extends StatelessWidget {
  const _ViewerPill({required this.viewers});

  final String viewers;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          VoiceRoomsSvgIcons.icon('eye', size: 10, color: Colors.white70),
          const SizedBox(width: 3),
          Text(
            viewers,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Stack(
        children: [
          for (var i = 0; i < colors.length; i++)
            Positioned(
              left: i * 18.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[i],
                  border: Border.all(color: const Color(0xFF050505), width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniAvatarRow extends StatelessWidget {
  const _MiniAvatarRow({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 18,
      child: Stack(
        children: [
          for (var i = 0; i < 4; i++)
            Positioned(
              left: i * 12.0,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors[i % colors.length],
                  border: Border.all(color: const Color(0xFF050505), width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
