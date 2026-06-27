import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../vip_gold/presentation/utils/open_voice_room_vip.dart';

/// Temel oda listesi — başlık, sahip, çevrimiçi sayısı.
class VoiceRoomBasicList extends StatelessWidget {
  const VoiceRoomBasicList({
    super.key,
    required this.rooms,
    required this.ref,
  });

  final List<VoiceRoomEntity> rooms;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: rooms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final room = rooms[index];
        final online = room.displayOnline;
        final owner = room.ownerName?.trim();
        return Material(
          color: context.colors.surfaceContainer.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => openVoiceRoomWithVipGate(context, ref, room),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppThemeColors.accentPink.withValues(alpha: 0.2),
                    backgroundImage: room.ownerAvatarUrl != null &&
                            room.ownerAvatarUrl!.isNotEmpty
                        ? NetworkImage(room.ownerAvatarUrl!)
                        : null,
                    child: room.ownerAvatarUrl == null ||
                            room.ownerAvatarUrl!.isEmpty
                        ? const Icon(Icons.mic_rounded, color: AppThemeColors.accentPink)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          owner != null && owner.isNotEmpty
                              ? 'Sahip: $owner'
                              : 'Sesli sohbet odası',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.colors.onSurfaceMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.people_rounded,
                        size: 18,
                        color: context.colors.onSurfaceMuted,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$online',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: online > 0
                              ? AppThemeColors.onlineGreen
                              : context.colors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.onSurfaceMuted,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
