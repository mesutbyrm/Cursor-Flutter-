import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../voice_hub/presentation/widgets/voice_room_grid_tile.dart';

/// Tek sohbet odası — üstte oda kartı, altta odadaki kullanıcı avatarları.
class DiscoverVoiceRoomCarouselItem extends StatelessWidget {
  const DiscoverVoiceRoomCarouselItem({
    super.key,
    required this.room,
    required this.onTap,
  });

  final VoiceRoomEntity room;
  final VoidCallback onTap;

  static const double tileWidth = 168;

  @override
  Widget build(BuildContext context) {
    final avatars = _collectAvatars(room);

    return SizedBox(
      width: tileWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: tileWidth / VoiceRoomGridTile.tileAspectRatio,
            child: VoiceRoomGridTile(room: room, onTap: onTap),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 28,
            child: avatars.isEmpty
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Henüz kimse yok',
                      style: TextStyle(
                        fontSize: 9,
                        color: context.colors.onSurfaceMuted.withValues(alpha: 0.8),
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: avatars.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 4),
                    itemBuilder: (_, i) => _MiniPresenceAvatar(url: avatars[i]),
                  ),
          ),
        ],
      ),
    );
  }

  List<String> _collectAvatars(VoiceRoomEntity room) {
    final urls = <String>[
      if (room.ownerAvatarUrl != null && room.ownerAvatarUrl!.isNotEmpty)
        room.ownerAvatarUrl!,
      ...room.recentUserAvatars,
    ];
    final seen = <String>{};
    final out = <String>[];
    for (final u in urls) {
      if (u.isEmpty || seen.contains(u)) continue;
      seen.add(u);
      out.add(u);
      if (out.length >= 12) break;
    }
    return out;
  }
}

class _MiniPresenceAvatar extends StatelessWidget {
  const _MiniPresenceAvatar({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppThemeColors.accentPink.withValues(alpha: 0.65),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppThemeColors.accentPurple.withValues(alpha: 0.25),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, _) => ColoredBox(
            color: context.colors.surfaceContainer,
            child: Icon(
              Icons.person,
              size: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          errorWidget: (_, _, _) => ColoredBox(
            color: context.colors.surfaceContainer,
            child: Icon(
              Icons.person,
              size: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
