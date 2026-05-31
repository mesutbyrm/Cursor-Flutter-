import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../vip_gold/domain/voice_room_access.dart';
import '../../../vip_gold/presentation/theme/vip_gold_tokens.dart';

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

  /// Daha büyük karo (ana sayfa + tüm odalar).
  static const tileAspectRatio = 0.92;

  @override
  Widget build(BuildContext context) {
    final bg = room.backgroundImageUrl;
    final isVip = room.isVipGoldRoom;
    final isLocked = room.isPasswordLockedRoom;
    final borderColor = isMine
        ? AppColors.coinGold
        : isVip
            ? VipGoldTokens.goldMid
            : AppColors.accentPurple.withValues(alpha: 0.5);

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
                color: (isMine ? AppColors.coinGold : AppColors.accentPink)
                    .withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: AspectRatio(
              aspectRatio: VoiceRoomGridTile.tileAspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isVip || isLocked)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Row(
                        children: [
                          if (isVip) const _TagChip(label: 'VIP', gold: true),
                          if (isLocked) ...[
                            if (isVip) const SizedBox(width: 4),
                            const _TagChip(label: '🔒', gold: false),
                          ],
                        ],
                      ),
                    ),
                  if (room.displayOnline > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _OnlineBadge(count: room.displayOnline),
                    ),
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
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            room.icon ?? '💬',
                            style: const TextStyle(fontSize: 20),
                          ),
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
                                  color: AppColors.coinGold.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'BENİM',
                                  style: TextStyle(
                                    fontSize: 6,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.coinGold,
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
                            fontSize: 11,
                            height: 1.1,
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
                              color: AppColors.accentCyan.withValues(alpha: 0.9),
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

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.gold});

  final String label;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: gold ? VipGoldTokens.goldLuxury : null,
        color: gold ? null : Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: gold ? VipGoldTokens.goldLight : Colors.white24,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: gold ? Colors.black87 : Colors.white,
        ),
      ),
    );
  }
}

class _OnlineBadge extends StatelessWidget {
  const _OnlineBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE53935),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.55),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1,
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
          color: AppColors.accentPink.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover)
            : ColoredBox(
                color: AppColors.bgPurpleGlow,
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
