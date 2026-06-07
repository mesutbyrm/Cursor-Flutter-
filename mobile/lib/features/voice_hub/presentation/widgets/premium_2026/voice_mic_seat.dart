import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../../../domain/entities/chat_room_presence.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/vip_gold/presentation/widgets/vip_badge.dart';
import '../../theme/voice_room_tokens.dart';
import 'voice_audio_wave_ring.dart';
import 'voice_seat_avatar_frame.dart';

/// Tek mikrofon koltuğu — boş, kilitli veya dolu.
class VoiceMicSeat extends StatelessWidget {
  const VoiceMicSeat({
    super.key,
    this.user,
    required this.seatIndex,
    this.speaking = false,
    this.size = 56,
    this.isHost = false,
    this.locked = false,
    this.room,
    this.djUserIds = const [],
    this.onTap,
  });

  final ChatRoomPresence? user;
  final int seatIndex;
  final bool speaking;
  final double size;
  final bool isHost;
  final bool locked;
  final VoiceRoomEntity? room;
  final List<String> djUserIds;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return _EmptySeat(
        seatIndex: seatIndex,
        size: size,
        locked: locked,
        onTap: onTap,
      );
    }

    final vipTier = VipTier.fromMembership(user!.membership);
    final vip = vipTier.isVip;
    final levelLabel = _levelLabel(user!);

    final avatar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: onTap,
              child: VoiceSeatAvatarFrame(
                imageUrl: user!.image,
                size: size,
                role: SeatAvatarRoleResolver.resolve(
                  user: user!,
                  isHost: isHost,
                  isRoomDj: djUserIds.contains(user!.id) ||
                      room?.djUserIds.contains(user!.id) == true,
                ),
                speaking: speaking,
              ),
            ),
            if (vip && !isHost)
              Positioned(
                bottom: -2,
                left: 0,
                right: 0,
                child: Center(child: VipBadge(tier: vipTier, compact: true)),
              ),
            if (levelLabel != null && !isHost)
              Positioned(
                top: -2,
                left: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    gradient: VoiceRoomTokens.neonRing,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    levelLabel,
                    style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (!isHost && seatIndex > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    '$seatIndex',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          isHost ? 'HOST' : user!.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: size > 60 ? 11 : 9,
            fontWeight: FontWeight.w800,
            color: isHost ? VoiceRoomTokens.gold : Colors.white,
          ),
        ),
      ],
    );

    if (!speaking && !isHost) return avatar;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return avatar;
    }

    return VoiceAudioWaveRing(
      size: size,
      active: speaking,
      goldHost: isHost,
      child: avatar,
    );
  }
}

String? _levelLabel(ChatRoomPresence user) {
  final sym = user.roleSymbol?.trim();
  if (sym != null && sym.isNotEmpty && sym.length <= 6) return sym;
  if (user.isBroadcaster) return 'MOD';
  final seat = user.seatIndex;
  if (seat != null && seat > 1) return 'Lv$seat';
  return null;
}

class _EmptySeat extends StatelessWidget {
  const _EmptySeat({
    required this.seatIndex,
    required this.size,
    required this.locked,
    this.onTap,
  });

  final int seatIndex;
  final double size;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: locked
                    ? context.colors.onSurfaceMuted.withValues(alpha: 0.35)
                    : VoiceRoomTokens.neonPurple.withValues(alpha: 0.55),
                width: 1.8,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
              boxShadow: locked
                  ? null
                  : [
                      BoxShadow(
                        color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.15),
                        blurRadius: 10,
                      ),
                    ],
            ),
            child: Icon(
              locked ? Icons.lock_rounded : Icons.add_rounded,
              color: locked ? context.colors.onSurfaceMuted : Colors.white54,
              size: size * 0.32,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            locked ? 'Kilit' : '$seatIndex',
            style: TextStyle(
              fontSize: size > 50 ? 10 : 9,
              fontWeight: FontWeight.w700,
              color: locked
                  ? context.colors.onSurfaceMuted.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }
}
