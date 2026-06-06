import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter/services.dart';

import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../profile/presentation/widgets/premium/profile_glass.dart';

class VoiceRoomTopBar extends StatelessWidget {
  const VoiceRoomTopBar({
    super.key,
    required this.room,
    required this.onlineCount,
    required this.onBack,
    required this.onExit,
    this.onShare,
    this.isCurrentUserOwner = false,
  });

  final VoiceRoomEntity room;
  final int onlineCount;
  final VoidCallback onBack;
  final VoidCallback onExit;
  final VoidCallback? onShare;
  final bool isCurrentUserOwner;

  @override
  Widget build(BuildContext context) {
    final shortId = room.id.length > 12 ? room.id.substring(0, 12) : room.id;
    final ownerLabel = room.ownerName?.trim().isNotEmpty == true
        ? room.ownerName!.trim()
        : 'Oda sahibi';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              _RoomAvatar(url: room.ownerAvatarUrl, icon: room.icon),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            room.displayTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppThemeColors.coinGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppThemeColors.coinGold.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            isCurrentUserOwner ? 'BENİM ODAM' : 'Sahip · $ownerLabel',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              color: AppThemeColors.coinGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: room.id));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Oda ID kopyalandı')),
                        );
                      },
                      child: Text(
                        'ID: $shortId',
                        style: TextStyle(
                          color: context.colors.onSurfaceMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _OnlineChip(count: onlineCount),
              if (onShare != null)
                _HeaderIcon(icon: Icons.share_outlined, onTap: onShare!),
              _HeaderIcon(
                icon: Icons.power_settings_new_rounded,
                color: AppThemeColors.liveRed,
                onTap: onExit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomAvatar extends StatelessWidget {
  const _RoomAvatar({this.url, this.icon});

  final String? url;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppThemeColors.accentPink, width: 2),
        boxShadow: AppThemeColors.glowShadow(AppThemeColors.accentPink, blur: 10),
      ),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover)
            : ColoredBox(
                color: context.colors.surfaceContainer,
                child: Center(
                  child: Text(icon ?? '💬', style: TextStyle(fontSize: 20)),
                ),
              ),
      ),
    );
  }
}

class _OnlineChip extends StatelessWidget {
  const _OnlineChip({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ProfileGlass(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        borderRadius: 14,
        blur: 8,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_alt_rounded, size: 14, color: AppThemeColors.accentCyan),
            SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  const _HeaderIcon({
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: color ?? Colors.white70),
      padding: const EdgeInsets.all(6),
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}
