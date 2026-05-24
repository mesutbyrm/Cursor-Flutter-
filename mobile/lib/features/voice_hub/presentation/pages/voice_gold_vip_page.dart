import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../theme/voice_room_tokens.dart';
import '../widgets/premium_2026/voice_cosmic_background.dart';
import '../widgets/premium_2026/voice_mic_seat.dart';

/// Gold VIP odası — tam ekran premium giriş / üyelik.
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
              scale: Tween<double>(begin: 0.94, end: 1).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
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
    final guests = List.generate(
      6,
      (i) => ChatRoomPresence(
        id: 'vip-$i',
        name: ['Elif', 'Kaan', 'Zeynep', 'Mert', 'Selin', 'Deniz'][i],
        chatRole: 'vip',
        membership: 'gold',
        seatIndex: i + 2,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const VoiceCosmicBackground(),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: VoiceRoomTokens.gold.withValues(alpha: 0.45),
                width: 2,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _GoldHeader(
                  roomId: room.apiRoomKey,
                  onClose: () => Navigator.of(context).pop(),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: VoiceRoomTokens.gold,
                  size: 36,
                ),
                ShaderMask(
                  shaderCallback: (b) => VoiceRoomTokens.goldRing.createShader(b),
                  child: const Text(
                    'GOLD VIP ODASI',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _WingsEmblem(child: VoiceMicSeat(
                          user: host,
                          seatIndex: 1,
                          size: 88,
                          isHost: true,
                          speaking: true,
                        )),
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (var i = 0; i < guests.length; i++)
                              SizedBox(
                                width: 72,
                                child: VoiceMicSeat(
                                  user: guests[i],
                                  seatIndex: i + 2,
                                  size: 52,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _PerksCard(),
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
                  child: _GoldCta(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (onJoinRoom != null) {
                        onJoinRoom!();
                      } else {
                        context.push('/premium-membership');
                      }
                    },
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

class _GoldHeader extends StatelessWidget {
  const _GoldHeader({required this.roomId, required this.onClose});

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
            icon: const Icon(Icons.close_rounded, color: VoiceRoomTokens.gold),
          ),
          const Spacer(),
          Column(
            children: [
              const Icon(Icons.lock_rounded, color: VoiceRoomTokens.gold, size: 20),
              Text(
                'ID: $short',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textMuted.withValues(alpha: 0.9),
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

class _WingsEmblem extends StatelessWidget {
  const _WingsEmblem({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.auto_awesome,
          size: 200,
          color: VoiceRoomTokens.gold.withValues(alpha: 0.15),
        ),
        Positioned(
          left: -20,
          child: Icon(
            Icons.flutter_dash,
            size: 48,
            color: VoiceRoomTokens.gold.withValues(alpha: 0.35),
          ),
        ),
        Positioned(
          right: -20,
          child: Icon(
            Icons.flutter_dash,
            size: 48,
            color: VoiceRoomTokens.gold.withValues(alpha: 0.35),
          ),
        ),
        child,
      ],
    );
  }
}

class _PerksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const perks = [
      (Icons.stars_rounded, 'Özel Rozet'),
      (Icons.auto_fix_high_rounded, 'Özel Efekt'),
      (Icons.mic_rounded, 'Öncelikli Mikrofon'),
      (Icons.block_flipped, 'Reklamsız'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(VoiceRoomTokens.radiusCard),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
          decoration: VoiceRoomTokens.glassCard(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final p in perks)
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: VoiceRoomTokens.goldRing,
                        boxShadow: VoiceRoomTokens.goldGlow(blur: 10),
                      ),
                      child: Icon(p.$1, color: Colors.black87, size: 22),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.$2,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: VoiceRoomTokens.gold,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldCta extends StatelessWidget {
  const _GoldCta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE082), Color(0xFFFF8F00), Color(0xFFE65100)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: VoiceRoomTokens.goldGlow(blur: 20),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.diamond_rounded, color: Colors.white, size: 22),
              SizedBox(width: 8),
              Text(
                'Gold Üye Ol',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
