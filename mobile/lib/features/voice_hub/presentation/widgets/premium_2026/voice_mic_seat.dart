import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../../../../agora/presentation/agora_room_manager.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import 'package:canlifal_social/features/vip_gold/domain/vip_tier.dart';
import 'package:canlifal_social/features/vip_gold/presentation/widgets/vip_badge.dart';
import '../../theme/voice_room_tokens.dart';
import 'voice_seat_avatar_frame.dart';

/// Tek mikrofon koltuğu — boş, kilitli veya dolu (Faz 12 cam yuvarlak tasarım).
class VoiceMicSeat extends StatelessWidget {
  const VoiceMicSeat({
    super.key,
    this.user,
    required this.seatIndex,
    this.speaking = false,
    this.micOpen,
    this.size = 56,
    this.isHost = false,
    this.locked = false,
    this.room,
    this.djUserIds = const [],
    this.onTap,
    this.agora,
    this.agoraReady = false,
    this.selfUserId,
    this.remoteAgoraUid,
  });

  final ChatRoomPresence? user;
  final int seatIndex;
  final bool speaking;
  /// null ise [ChatRoomPresence.micOpen] veya koltukta varsayılan açık.
  final bool? micOpen;
  final double size;
  final bool isHost;
  final bool locked;
  final VoiceRoomEntity? room;
  final List<String> djUserIds;
  final VoidCallback? onTap;
  final AgoraRoomManager? agora;
  final bool agoraReady;
  final String? selfUserId;
  final int? remoteAgoraUid;

  bool _resolveMicOpen(ChatRoomPresence u) =>
      micOpen ?? (u.seatIndex != null ? !u.isMuted : false);

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
    final videoChild = _agoraVideoChild();
    final micOn = _resolveMicOpen(user!);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: onTap,
              child: videoChild != null
                  ? ClipOval(
                      child: SizedBox(
                        width: size,
                        height: size,
                        child: videoChild,
                      ),
                    )
                  : VoiceSeatAvatarFrame(
                      imageUrl: user!.image,
                      size: size,
                      role: SeatAvatarRoleResolver.resolve(
                        user: user!,
                        isHost: isHost,
                        isRoomDj: djUserIds.contains(user!.id) ||
                            room?.djUserIds.contains(user!.id) == true,
                      ),
                      speaking: speaking,
                      micOpen: micOn,
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
                    gradient: micOn
                        ? VoiceRoomTokens.neonRing
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade600,
                              Colors.grey.shade700,
                            ],
                          ),
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
            if (!micOn)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Icon(
                    Icons.mic_off_rounded,
                    size: size * 0.16,
                    color: Colors.grey.shade400,
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
            color: isHost
                ? (micOn ? VoiceRoomTokens.gold : Colors.grey.shade500)
                : (micOn ? Colors.white : Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget? _agoraVideoChild() {
    final manager = agora;
    if (!agoraReady || manager == null || user == null) return null;
    final uid = user!.id;
    final self = selfUserId;
    if (self != null && uid == self && manager.isHost && manager.cameraOn) {
      return AgoraLocalVideoView(manager: manager);
    }
    if (!isHost) return null;
    final remote = remoteAgoraUid ?? manager.remoteUid;
    if (remote != null &&
        remote > 0 &&
        uid != self &&
        manager.remoteVideoAvailable.value) {
      return AgoraRemoteVideoView(manager: manager, uid: remote);
    }
    return null;
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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: locked
                    ? [
                        Colors.white.withValues(alpha: 0.04),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.white.withValues(alpha: 0.04),
                      ],
              ),
              border: Border.all(
                color: locked
                    ? context.colors.onSurfaceMuted.withValues(alpha: 0.35)
                    : VoiceRoomTokens.neonPurple.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: locked
                  ? null
                  : [
                      BoxShadow(
                        color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.2),
                        blurRadius: 12,
                      ),
                    ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: size * 0.55,
                    height: size * 0.55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: locked ? 0.06 : 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Icon(
                  locked ? Icons.lock_rounded : Icons.add_rounded,
                  color: locked ? context.colors.onSurfaceMuted : Colors.white54,
                  size: size * 0.32,
                ),
              ],
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
