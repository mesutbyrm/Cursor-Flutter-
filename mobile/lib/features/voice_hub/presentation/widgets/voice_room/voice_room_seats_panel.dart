import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_design.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_presence.dart';

/// Web ile aynı 2×5 koltuk ızgarası (10 koltuk).
class VoiceRoomSeatsPanel extends StatelessWidget {
  const VoiceRoomSeatsPanel({
    super.key,
    required this.room,
    required this.presence,
    this.speakingUserId,
  });

  final VoiceRoomEntity room;
  final List<ChatRoomPresence> presence;
  final String? speakingUserId;

  static const seatCount = 10;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) => _seat(i + 1)),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) => _seat(i + 6)),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: room.id));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Oda ID: ${room.id.length > 14 ? '${room.id.substring(0, 14)}…' : room.id}',
                  style: const TextStyle(fontSize: 10, color: AppDesign.textMuted),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.copy_rounded, size: 12, color: AppDesign.textMuted),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _seat(int index) {
    if (index == 1) {
      return _OccupiedSeat(
        index: index,
        name: room.ownerName ?? 'Admin',
        avatarUrl: room.ownerAvatarUrl,
        isOwner: true,
        speaking: speakingUserId == room.ownerId,
      );
    }
    final userIndex = index - 2;
    if (userIndex >= 0 && userIndex < presence.length) {
      final u = presence[userIndex];
      return _OccupiedSeat(
        index: index,
        name: u.displayName,
        avatarUrl: u.image,
        speaking: speakingUserId == u.id,
      );
    }
    return _EmptySeat(index: index);
  }
}

class _OccupiedSeat extends StatelessWidget {
  const _OccupiedSeat({
    required this.index,
    required this.name,
    this.avatarUrl,
    this.isOwner = false,
    this.speaking = false,
  });

  final int index;
  final String name;
  final String? avatarUrl;
  final bool isOwner;
  final bool speaking;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isOwner ? AppDesign.coinGold : (speaking ? AppDesign.accentPink : AppDesign.accentPurple);

    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: isOwner ? 3 : 2),
                  boxShadow: speaking
                      ? AppDesign.glowShadow(AppDesign.accentPink, blur: 12)
                      : (isOwner ? AppDesign.glowShadow(AppDesign.coinGold, blur: 10) : null),
                ),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? CachedNetworkImage(imageUrl: avatarUrl!, fit: BoxFit.cover)
                      : ColoredBox(
                          color: AppDesign.bgPurpleGlow,
                          child: Icon(Icons.person, color: Colors.white54, size: 28),
                        ),
                ),
              ),
              if (isOwner)
                const Positioned(
                  top: -8,
                  right: -4,
                  child: Text('👑', style: TextStyle(fontSize: 18)),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppDesign.onlineGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_rounded, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            isOwner ? '👑 $name' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isOwner ? AppDesign.coinGold : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySeat extends StatelessWidget {
  const _EmptySeat({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$index',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
        ],
      ),
    );
  }
}
