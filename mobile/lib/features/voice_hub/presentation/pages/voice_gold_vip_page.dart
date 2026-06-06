import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../vip_gold/presentation/theme/vip_gold_tokens.dart';
import '../../../vip_gold/presentation/widgets/vip_luxury_card.dart';
import '../../../vip_gold/presentation/widgets/vip_privilege_grid.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../../../vip_gold/domain/vip_tier.dart';
import '../widgets/premium_2026/voice_cosmic_background.dart';
import '../widgets/premium_2026/voice_mic_seat.dart';

/// Gold VIP oda kapısı — luxury giriş + üyelik CTA.
class VoiceGoldVipPage extends StatelessWidget {
  const VoiceGoldVipPage({
    super.key,
    required this.room,
    this.onJoinRoom,
  });

  final VoiceRoomEntity room;
  final VoidCallback? onJoinRoom;

  static Future<void> show(
    BuildContext context, {
    required VoiceRoomEntity room,
    VoidCallback? onJoinRoom,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) => VoiceGoldVipPage(
          room: room,
          onJoinRoom: onJoinRoom,
        ),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final host = ChatRoomPresence(
      id: room.ownerId ?? 'host',
      name: room.ownerName ?? 'HOST',
      image: room.ownerAvatarUrl,
      chatRole: 'owner',
      membership: 'gold',
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const VoiceCosmicBackground(),
          const DecoratedBox(
            decoration: BoxDecoration(gradient: VipGoldTokens.goldRadial),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: VipGoldTokens.goldMid.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _Header(
                  roomId: room.apiRoomKey,
                  onClose: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 12),
                ShaderMask(
                  shaderCallback: (b) => VipGoldTokens.goldLuxury.createShader(b),
                  child: const Text(
                    'GOLD VIP ODASI',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  room.displayTitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        VoiceMicSeat(
                          user: host,
                          seatIndex: 1,
                          size: 96,
                          isHost: true,
                          speaking: true,
                        ),
                        const SizedBox(height: 20),
                        const VipPrivilegeGrid(tier: VipTier.gold),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    8,
                    20,
                    MediaQuery.paddingOf(context).bottom + 16,
                  ),
                  child: VipLuxuryCard(
                    highlighted: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      if (onJoinRoom != null) {
                        onJoinRoom!();
                      } else {
                        context.push('/vip-gold');
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.diamond_rounded, color: Colors.black87),
                        SizedBox(width: 8),
                        Text(
                          'Gold Üye Ol · Odaya Gir',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.roomId, required this.onClose});

  final String roomId;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final short = roomId.length > 8 ? roomId.substring(0, 8) : roomId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: VipGoldTokens.goldMid),
          ),
          const Spacer(),
          Column(
            children: [
              const Icon(Icons.lock_rounded, color: VipGoldTokens.goldMid, size: 22),
              Text(
                'ID: $short',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
