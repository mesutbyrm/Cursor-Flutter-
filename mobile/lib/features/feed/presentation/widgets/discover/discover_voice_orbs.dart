import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/theme/app_design.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import 'discover_section_header.dart';

class DiscoverVoiceOrbs extends ConsumerWidget {
  const DiscoverVoiceOrbs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.useNextAuth) {
      return _DemoOrbs(onOpen: (_) => context.push('/voice-rooms'));
    }

    final rooms = ref.watch(voiceRoomsProvider);
    return rooms.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => _DemoOrbs(onOpen: (_) => context.push('/voice-rooms')),
      data: (list) {
        if (list.isEmpty) {
          return _DemoOrbs(onOpen: (_) => context.push('/voice-rooms'));
        }
        return _OrbsGrid(rooms: list);
      },
    );
  }
}

class _OrbsGrid extends StatelessWidget {
  const _OrbsGrid({required this.rooms});

  final List<VoiceRoomEntity> rooms;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoverSectionHeader(
          title: 'Sohbet Odaları',
          actionLabel: 'Tüm Odalar',
          onAction: () => context.push('/voice-rooms'),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 14,
            alignment: WrapAlignment.start,
            children: [
              for (var i = 0; i < rooms.length; i++)
                _VoiceOrbTile(
                  title: rooms[i].displayTitle,
                  count: rooms[i].displayOnline,
                  icon: rooms[i].icon ?? '💬',
                  orbColors: _orbPalette(i),
                  onTap: () => context.push(
                    '/voice-room/${rooms[i].id}',
                    extra: rooms[i],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _DemoOrbs extends StatelessWidget {
  const _DemoOrbs({required this.onOpen});

  final void Function(VoiceRoomEntity? room) onOpen;

  static const _items = [
    ('Müzik Keyfi', 12, '🎤'),
    ('Gece Sohbeti', 8, '💬'),
    ('VIP Lounge', 24, '⭐'),
    ('Kahve Sohbet', 5, '☕'),
    ('DJ Odası', 18, '🎧'),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 14,
            children: [
              for (var i = 0; i < _items.length; i++)
                _VoiceOrbTile(
                  title: _items[i].$1,
                  count: _items[i].$2,
                  icon: _items[i].$3,
                  orbColors: _orbPalette(i),
                  onTap: () => onOpen(null),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

List<Color> _orbPalette(int i) {
  switch (i % 4) {
    case 0:
      return [const Color(0xFF7C3AED), const Color(0xFF2563EB)];
    case 1:
      return [const Color(0xFF6366F1), const Color(0xFF06B6D4)];
    case 2:
      return [const Color(0xFFF59E0B), const Color(0xFFEAB308)];
    default:
      return [const Color(0xFFEC4899), const Color(0xFF8B5CF6)];
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
      width: 88,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
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
                              color: orbColors.first.withValues(alpha: 0.45),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(icon, style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppDesign.onlineGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppDesign.bgBase, width: 2),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppDesign.bgBase.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: orbColors.first.withValues(alpha: 0.45),
                          ),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 3; i++)
                    Transform.translate(
                      offset: Offset(-7.0 * i, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: AppDesign.bgBase, width: 1.2),
                        ),
                        child: UserAvatar(
                          radius: 8,
                          url: 'https://i.pravatar.cc/48?img=${20 + i}',
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  color: AppDesign.textPrimary,
                ),
              ),
              Text(
                '$count kişi',
                style: const TextStyle(
                  fontSize: 10,
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
