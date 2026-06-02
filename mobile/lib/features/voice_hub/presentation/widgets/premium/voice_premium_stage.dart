import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../domain/entities/chat_room_presence.dart';
import '../../utils/voice_room_seat_layout.dart';
import 'voice_neon_avatar.dart';

/// Clubhouse / Discord tarzı — büyük sahip, konuşmacı koltukları, dinleyici sırası.
class VoicePremiumStage extends StatelessWidget {
  const VoicePremiumStage({
    super.key,
    required this.room,
    required this.presence,
    this.speakingUserId,
    this.onUserTap,
  });

  final VoiceRoomEntity room;
  final List<ChatRoomPresence> presence;
  final String? speakingUserId;
  final void Function(ChatRoomPresence user)? onUserTap;

  @override
  Widget build(BuildContext context) {
    final seats = VoiceRoomSeatLayout(room: room, presence: presence).build();
    final ownerFromSeat = seats[1];
    final owner = ownerFromSeat ??
        (presence.isEmpty && room.ownerName != null
            ? ChatRoomPresence(
                id: room.ownerId ?? 'owner',
                name: room.ownerName!,
                image: room.ownerAvatarUrl,
                chatRole: 'owner',
                seatIndex: 1,
              )
            : null);

    final speakers = <ChatRoomPresence>[];
    for (var i = 2; i <= 6; i++) {
      final u = seats[i];
      if (u != null) speakers.add(u);
    }
    if (speakers.isEmpty && presence.length > 1) {
      for (final u in presence) {
        if (owner != null && u.id == owner.id) continue;
        if (u.isSpeaking ||
            u.chatRole == 'owner' ||
            u.chatRole == 'admin' ||
            u.chatRole == 'dj' ||
            room.djUserIds.contains(u.id)) {
          speakers.add(u);
        }
        if (speakers.length >= 5) break;
      }
    }

    final listeners = <ChatRoomPresence>[];
    for (var i = 7; i <= 10; i++) {
      final u = seats[i];
      if (u != null) listeners.add(u);
    }
    final speakerIds = speakers.map((s) => s.id).toSet();
    if (owner != null) speakerIds.add(owner.id);
    final extraListeners = presence
        .where((p) => !speakerIds.contains(p.id))
        .take(8)
        .toList();

    final allVisible = [
      if (owner != null) owner,
      ...speakers,
      ...listeners,
      ...extraListeners,
    ];
    final unique = <String, ChatRoomPresence>{};
    for (final u in allVisible) {
      unique.putIfAbsent(u.id, () => u);
    }
    final totalOnline = presence.isNotEmpty ? presence.length : unique.length;

    return Column(
      children: [
        VoiceNeonAvatar(
          url: owner?.image ?? room.ownerAvatarUrl,
          size: 88,
          speaking: speakingUserId == owner?.id,
          showCrown: true,
          roleLabel: owner?.displayName ?? room.ownerName ?? 'Sahip',
          onTap: owner != null ? () => onUserTap?.call(owner) : null,
        ),
        const SizedBox(height: 16),
        if (speakers.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 12,
            children: speakers.map((u) {
              final isMod = room.djUserIds.contains(u.id);
              return VoiceNeonAvatar(
                url: u.image,
                size: 58,
                speaking: speakingUserId == u.id || u.isSpeaking,
                roleLabel: isMod ? 'Yönetici' : u.displayName,
                onTap: () => onUserTap?.call(u),
              );
            }).toList(),
          )
        else if (presence.length > 1)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 12,
            children: presence
                .where((p) => owner == null || p.id != owner.id)
                .take(5)
                .map(
                  (u) => VoiceNeonAvatar(
                    url: u.image,
                    size: 58,
                    speaking: speakingUserId == u.id || u.isSpeaking,
                    roleLabel: u.displayName,
                    onTap: () => onUserTap?.call(u),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 14),
        _ListenerRow(
          users: [...listeners, ...extraListeners],
          totalOnline: totalOnline,
          onUserTap: onUserTap,
        ),
        if (totalOnline == 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Henüz kimse görünmüyor — sohbet ve liste birkaç saniye içinde güncellenir',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
              ),
            ),
          ),
      ],
    );
  }
}

class _ListenerRow extends StatelessWidget {
  const _ListenerRow({
    required this.users,
    required this.totalOnline,
    this.onUserTap,
  });

  final List<ChatRoomPresence> users;
  final int totalOnline;
  final void Function(ChatRoomPresence user)? onUserTap;

  @override
  Widget build(BuildContext context) {
    final show = users.take(5).toList();
    final overflow = totalOnline > show.length ? totalOnline - show.length : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final u in show)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: VoiceNeonAvatar(
              url: u.image,
              size: 40,
              onTap: () => onUserTap?.call(u),
            ),
          ),
        if (overflow > 0)
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white24),
            ),
            child: Text(
              '+$overflow',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
        if (show.isEmpty && totalOnline > 0)
          Text(
            '$totalOnline kişi çevrimiçi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
            ),
          ),
      ],
    );
  }
}
