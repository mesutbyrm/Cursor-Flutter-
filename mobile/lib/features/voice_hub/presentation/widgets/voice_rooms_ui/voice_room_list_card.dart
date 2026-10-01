import 'package:flutter/material.dart';

import '../../../../../core/images/canlifal_network_image.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import 'voice_rooms_2026.dart';
import 'voice_rooms_ui_tokens.dart';

/// Oda müsait mi? Kilitli/şifreli veya dolu odalar "Müsait" rozeti almaz.
({String label, Color color}) voiceRoomAvailability(VoiceRoomEntity r) {
  if (r.isLocked == true || r.hasPassword == true) {
    return (label: 'Kilitli', color: VoiceRoomsUiTokens.orange);
  }
  final max = r.maxUsers;
  if (max != null && max > 0 && r.userCount >= max) {
    return (label: 'Dolu', color: VoiceRoomsUiTokens.badgeRed);
  }
  return (label: 'Müsait', color: VoiceRoomsUiTokens.onlineGreen);
}

/// Oda listesi satırı (referans 2. ekran): görsel · ad · açıklama · etiketler ·
/// dinleyici · mini avatarlar · Müsait rozeti · Katıl.
class VoiceRoomListCard extends StatelessWidget {
  const VoiceRoomListCard({
    super.key,
    required this.room,
    required this.onJoin,
    this.rank,
  });

  final VoiceRoomEntity room;
  final VoidCallback onJoin;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final image = (room.backgroundImageUrl ?? room.ownerAvatarUrl)?.trim();
    final avail = voiceRoomAvailability(room);
    final extra = room.userCount > room.recentUserAvatars.length
        ? room.userCount - room.recentUserAvatars.length
        : 0;
    final desc = room.descTr?.trim();
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: VoiceRoomsUiTokens.gapMd),
        child: VrPressable(
          onTap: onJoin,
          semanticLabel: '${room.displayTitle}, ${avail.label}, katıl',
          child: Container(
            constraints: const BoxConstraints(minHeight: 112),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(VoiceRoomsUiTokens.radiusLg),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2A1252), Color(0xFF150A2B)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 96,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const ColoredBox(color: Color(0xFF3B1A70)),
                        if (image != null && image.isNotEmpty)
                          CanlifalNetworkImage(
                            url: image,
                            fit: BoxFit.cover,
                            thumbnailWidth: 240,
                            errorWidget: const SizedBox.shrink(),
                          ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [Color(0x00000000), Color(0x990F0620)],
                            ),
                          ),
                        ),
                        if (rank != null)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: rank == 1
                                    ? VoiceRoomsUiTokens.gold
                                    : VoiceRoomsUiTokens.purpleGlow,
                              ),
                              child: Text(
                                '$rank',
                                style: TextStyle(
                                  color: rank == 1
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  room.displayTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: avail.color.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: avail.color.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Text(
                                  avail.label,
                                  style: TextStyle(
                                    color: avail.color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (desc != null && desc.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                desc,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: VoiceRoomsUiTokens.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                size: 13,
                                color: VoiceRoomsUiTokens.textMuted,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                voiceRoomsCount(room.displayOnline),
                                style: const TextStyle(
                                  color: VoiceRoomsUiTokens.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (room.displayOnline > 0) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 16,
                                  color: VoiceRoomsUiTokens.onlineGreen,
                                ),
                              ],
                              const SizedBox(width: 8),
                              Flexible(child: VrCategoryChips(room: room)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: VrAvatarStack(
                                    urls: room.recentUserAvatars,
                                    extra: extra,
                                    radius: 11,
                                  ),
                                ),
                              ),
                              VrJoinButton(onTap: onJoin, compact: true),
                            ],
                          ),
                        ],
                      ),
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
