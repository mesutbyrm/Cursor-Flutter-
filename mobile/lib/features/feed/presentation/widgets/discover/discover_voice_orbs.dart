import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/theme/app_design.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import 'discover_section_header.dart';

class DiscoverVoiceOrbs extends ConsumerWidget {
  const DiscoverVoiceOrbs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.useNextAuth) {
      return _DemoOrbs(onOpen: (slug, title) {
        context.push('/voice-rooms');
      });
    }

    final rooms = ref.watch(voiceRoomsProvider);
    return rooms.when(
      loading: () => const SizedBox(
        height: 160,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => _DemoOrbs(onOpen: (_, _) => context.push('/voice-rooms')),
      data: (list) {
        if (list.isEmpty) {
          return _DemoOrbs(onOpen: (_, _) => context.push('/voice-rooms'));
        }
        return _OrbsList(rooms: list.take(6).toList());
      },
    );
  }
}

class _OrbsList extends StatelessWidget {
  const _OrbsList({required this.rooms});

  final List<VoiceRoomEntity> rooms;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DiscoverSectionHeader(
          title: 'Sohbet Odaları',
          actionLabel: 'Tüm Odalar',
          onAction: () => context.push('/voice-rooms'),
        ),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: rooms.length,
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (ctx, i) {
              final room = rooms[i];
              return _VoiceOrbTile(
                title: room.nameTr,
                count: room.onlineCount,
                icon: room.icon ?? '💬',
                orbColors: _orbPalette(i),
                onTap: () => context.push(
                  CanlifalWebRoute.location(
                    relativePath: '/sohbet/${room.slug}',
                    title: room.nameTr,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _DemoOrbs extends StatelessWidget {
  const _DemoOrbs({required this.onOpen});

  final void Function(String slug, String title) onOpen;

  static const _items = [
    ('Müzik Keyfi', 12, '🎤', 0),
    ('Gece Sohbeti', 8, '💬', 1),
    ('VIP Lounge', 24, '⭐', 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DiscoverSectionHeader(
          title: 'Sohbet Odaları',
          actionLabel: 'Tüm Odalar',
          onAction: () => context.push('/voice-rooms'),
        ),
        SizedBox(
          height: 148,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (ctx, i) {
              final (title, count, icon, palette) = _items[i];
              return _VoiceOrbTile(
                title: title,
                count: count,
                icon: icon,
                orbColors: _orbPalette(palette),
                onTap: () => onOpen('room-$i', title),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

List<Color> _orbPalette(int i) {
  switch (i % 3) {
    case 0:
      return [const Color(0xFF7C3AED), const Color(0xFF2563EB)];
    case 1:
      return [const Color(0xFF6366F1), const Color(0xFF06B6D4)];
    default:
      return [const Color(0xFFF59E0B), const Color(0xFFEAB308)];
  }
}

class _VoiceOrbTile extends StatelessWidget {
  const _VoiceOrbTile({
    required this.title,
    required this.count,
    required this.icon,
    required this.orbColors,
    required this.onTap,
  });

  final String title;
  final int count;
  final String icon;
  final List<Color> orbColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              SizedBox(
                width: AppDesign.orbSize,
                height: AppDesign.orbSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Container(
                        width: AppDesign.orbSize,
                        height: AppDesign.orbSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              orbColors.first.withValues(alpha: 0.95),
                              orbColors.last.withValues(alpha: 0.35),
                              Colors.transparent,
                            ],
                            stops: const [0.35, 0.7, 1],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: orbColors.first.withValues(alpha: 0.5),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(icon, style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppDesign.onlineGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppDesign.bgBase, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppDesign.onlineGreen.withValues(alpha: 0.6),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesign.bgBase.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: orbColors.first.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 3; i++)
                    Transform.translate(
                      offset: Offset(-8.0 * i, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppDesign.bgBase, width: 1.2),
                        ),
                        child: UserAvatar(
                          radius: 9,
                          url: 'https://i.pravatar.cc/48?img=${20 + i}',
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppDesign.textPrimary,
                ),
              ),
              Text(
                '$count kişi',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppDesign.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
