import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';
import 'home_section_header.dart';

/// Sesli sohbet — dairesel oda halkaları (canlifal.com).
class HomeVoiceRoomsRow extends ConsumerWidget {
  const HomeVoiceRoomsRow({super.key});

  static const _placeholderTitles = [
    'Sohbet',
    'CanlıFal',
    'Müzik',
    'Gece',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(homeVoiceRoomsProvider);

    return rooms.when(
      loading: () => _section(
        child: SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (_, __) => const PremiumSkeleton(
              width: 72,
              height: 72,
              borderRadius: BorderRadius.all(Radius.circular(36)),
            ),
          ),
        ),
      ),
      error: (_, __) => _section(child: _buildRow(context, const [])),
      data: (items) => _section(
        child: _buildRow(context, items.take(12).toList()),
      ),
    );
  }

  Widget _section({required Widget child}) {
    return Builder(
      builder: (context) => Column(
        children: [
          HomeSectionHeader(
            title: 'Sesli Sohbet Odaları',
            leadingDotColor: HomePalette.secondary,
            onTrailing: () => context.push('/voice-rooms'),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<VoiceRoomEntity> rooms) {
    final count = rooms.isEmpty ? _placeholderTitles.length : rooms.length;

    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          if (rooms.isEmpty) {
            return _PlaceholderOrb(
              title: _placeholderTitles[i % _placeholderTitles.length],
              color: _ringColor(i),
            );
          }
          final room = rooms[i];
          return _VoiceOrb(
            room: room,
            ringColor: _ringColor(i),
            onTap: () => context.push(
              '/voice-room/${room.apiRoomKey}',
              extra: room,
            ),
          );
        },
      ),
    );
  }

  Color _ringColor(int i) {
    const colors = [
      Color(0xFFFF4FD8),
      Color(0xFF25F4EE),
      Color(0xFF7B2FF7),
      Color(0xFFFF6B35),
      Color(0xFF22C55E),
      Color(0xFFFBBF24),
    ];
    return colors[i % colors.length];
  }
}

class _VoiceOrb extends StatelessWidget {
  const _VoiceOrb({
    required this.room,
    required this.ringColor,
    required this.onTap,
  });

  final VoiceRoomEntity room;
  final Color ringColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [ringColor, ringColor.withValues(alpha: 0.4)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ringColor.withValues(alpha: 0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: UserAvatar(
                url: room.ownerAvatarUrl,
                radius: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              room.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.colors.onSurface,
              ),
            ),
            Text(
              '${room.displayOnline} kişi',
              style: TextStyle(
                fontSize: 10,
                color: context.colors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderOrb extends StatelessWidget {
  const _PlaceholderOrb({required this.title, required this.color});

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.35)],
              ),
            ),
            child: CircleAvatar(
              backgroundColor: const Color(0xFF1A0E38),
              child: Icon(
                Icons.mic_rounded,
                color: color.withValues(alpha: 0.9),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: context.colors.onSurface,
            ),
          ),
          Text(
            '0 kişi',
            style: TextStyle(
              fontSize: 10,
              color: context.colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
