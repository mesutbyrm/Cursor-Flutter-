import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/app_design.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../profile/presentation/widgets/premium/profile_glass.dart';

class VoiceRoomTopBar extends StatelessWidget {
  const VoiceRoomTopBar({
    super.key,
    required this.room,
    required this.onlineCount,
    required this.onBack,
    required this.onExit,
  });

  final VoiceRoomEntity room;
  final int onlineCount;
  final VoidCallback onBack;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final shortId = room.id.length > 12
        ? room.id.substring(0, 12)
        : room.id;

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
              color: AppDesign.accentPurple.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              _RoomAvatar(url: room.ownerAvatarUrl, icon: room.icon),
              const SizedBox(width: 8),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppDesign.coinGold.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppDesign.coinGold.withValues(alpha: 0.6),
                            ),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: AppDesign.coinGold,
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
                        style: const TextStyle(
                          color: AppDesign.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _OnlineChip(count: onlineCount),
              _HeaderIcon(icon: Icons.photo_library_outlined, onTap: () {}),
              _HeaderIcon(icon: Icons.settings_outlined, onTap: () {}),
              _HeaderIcon(icon: Icons.bar_chart_rounded, onTap: () {}),
              _HeaderIcon(
                icon: Icons.power_settings_new_rounded,
                color: AppDesign.liveRed,
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
        border: Border.all(color: AppDesign.accentPink, width: 2),
        boxShadow: AppDesign.glowShadow(AppDesign.accentPink, blur: 10),
      ),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover)
            : ColoredBox(
                color: AppDesign.bgPurpleGlow,
                child: Center(
                  child: Text(icon ?? '💬', style: const TextStyle(fontSize: 20)),
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
            const Icon(Icons.people_alt_rounded, size: 14, color: AppDesign.accentCyan),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
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
