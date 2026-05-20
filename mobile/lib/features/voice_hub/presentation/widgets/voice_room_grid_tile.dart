import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_design.dart';
import '../../../live/domain/entities/voice_room_entity.dart';

/// Sesli oda listesi — 4 sütunlu grid için kompakt karo.
class VoiceRoomGridTile extends StatelessWidget {
  const VoiceRoomGridTile({
    super.key,
    required this.room,
    required this.onTap,
    this.isMine = false,
  });

  final VoiceRoomEntity room;
  final VoidCallback onTap;
  final bool isMine;

  static const crossAxisCount = 4;

  @override
  Widget build(BuildContext context) {
    final bg = room.backgroundImageUrl;
    final borderColor = isMine
        ? AppDesign.coinGold
        : AppDesign.accentPurple.withValues(alpha: 0.5);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: isMine ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isMine ? AppDesign.coinGold : AppDesign.accentPink)
                    .withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: AspectRatio(
              aspectRatio: 0.78,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (bg != null && bg.isNotEmpty)
                    CachedNetworkImage(imageUrl: bg, fit: BoxFit.cover)
                  else
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Text(
                              room.icon ?? '💬',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const Spacer(),
                            if (room.displayOnline > 0)
                              _OnlineDot(count: room.displayOnline),
                          ],
                        ),
                        if (isMine)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppDesign.coinGold.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'BENİM',
                                  style: TextStyle(
                                    fontSize: 6,
                                    fontWeight: FontWeight.w900,
                                    color: AppDesign.coinGold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const Spacer(),
                        Text(
                          room.displayTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                            height: 1.05,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            _MiniAvatar(url: room.ownerAvatarUrl),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                room.ownerName ?? 'Sahip',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 7,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.headset_mic_rounded,
                              size: 11,
                              color: AppDesign.accentCyan.withValues(alpha: 0.9),
                            ),
                          ],
                        ),
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

class _OnlineDot extends StatelessWidget {
  const _OnlineDot({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppDesign.onlineGreen.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppDesign.onlineGreen.withValues(alpha: 0.6),
          width: 0.8,
        ),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: AppDesign.onlineGreen,
        ),
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppDesign.accentPink.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover)
            : ColoredBox(
                color: AppDesign.bgPurpleGlow,
                child: Icon(
                  Icons.person,
                  size: 9,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
      ),
    );
  }
}
