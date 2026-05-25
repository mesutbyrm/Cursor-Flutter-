import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../../../vip_gold/presentation/widgets/vip_badge.dart';
import '../../theme/voice_room_tokens.dart';
import '../premium/voice_neon_avatar.dart';
import 'voice_audio_wave_ring.dart';

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
    this.onTap,
  });

  final ChatRoomPresence? user;
  final int seatIndex;
  final bool speaking;
  final double size;
  final bool isHost;
  final bool locked;
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

    final avatar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            VoiceNeonAvatar(
              url: user!.image,
              size: size,
              speaking: speaking,
              showCrown: isHost,
              roleLabel: null,
              onTap: onTap,
            ),
            if (vip && !isHost)
              Positioned(
                bottom: -2,
                left: 0,
                right: 0,
                child: Center(child: VipBadge(tier: vipTier, compact: true)),
              ),
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

    return VoiceAudioWaveRing(
      size: size,
      active: speaking,
      goldHost: isHost,
      child: avatar,
    );
  }
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
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: locked
                    ? AppColors.textMuted.withValues(alpha: 0.35)
                    : VoiceRoomTokens.neonPurple.withValues(alpha: 0.45),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Icon(
              locked ? Icons.lock_rounded : Icons.add_rounded,
              color: locked ? AppColors.textMuted : Colors.white54,
              size: size * 0.32,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            locked ? 'Kilit' : 'Boş',
            style: TextStyle(
              fontSize: size > 50 ? 10 : 8,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
