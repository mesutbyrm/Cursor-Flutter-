import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_design.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../utils/voice_room_seat_layout.dart';

/// 2×5 koltuk — 1. koltuk oda sahibine ayrılmış (yalnızca odadaysa dolu).
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

  @override
  Widget build(BuildContext context) {
    final seats = VoiceRoomSeatLayout(room: room, presence: presence).build();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) => _seat(i + 1, seats)),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) => _seat(i + 6, seats)),
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

  Widget _seat(int index, Map<int, ChatRoomPresence> seats) {
    if (index == 1) {
      final u = seats[1];
      if (u != null) {
        return _OccupiedSeat(
          index: index,
          name: u.displayName,
          avatarUrl: u.image,
          isOwner: true,
          speaking: speakingUserId == u.id,
        );
      }
      return _OwnerReservedSeat(
        ownerName: room.ownerName,
        avatarUrl: room.ownerAvatarUrl,
      );
    }

    final u = seats[index];
    if (u != null) {
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

class _OwnerReservedSeat extends StatelessWidget {
  const _OwnerReservedSeat({this.ownerName, this.avatarUrl});

  final String? ownerName;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final label = ownerName?.trim().isNotEmpty == true ? ownerName!.trim() : 'Sahip';

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
                  border: Border.all(
                    color: AppDesign.coinGold.withValues(alpha: 0.55),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                ),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl!.isNotEmpty
                      ? ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.35),
                            BlendMode.darken,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: avatarUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : ColoredBox(
                          color: AppDesign.bgPurpleGlow.withValues(alpha: 0.6),
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: AppDesign.coinGold.withValues(alpha: 0.7),
                            size: 28,
                          ),
                        ),
                ),
              ),
              const Positioned(
                top: -8,
                right: -4,
                child: Text('👑', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: AppDesign.coinGold.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
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
