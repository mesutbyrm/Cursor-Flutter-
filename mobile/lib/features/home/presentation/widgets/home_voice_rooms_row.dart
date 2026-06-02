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

class HomeVoiceRoomsRow extends ConsumerWidget {
  const HomeVoiceRoomsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(homeVoiceRoomsProvider);

    return rooms.when(
      loading: () => Column(
        children: [
          const HomeSectionHeader(
            title: 'Sesli Chat Odaları',
            leadingDotColor: HomePalette.secondary,
          ),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => const PremiumSkeleton(
                width: 160,
                height: 180,
                borderRadius: BorderRadius.all(Radius.circular(HomePalette.radiusCard)),
              ),
            ),
          ),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            HomeSectionHeader(
              title: 'Sesli Chat Odaları',
              leadingDotColor: HomePalette.secondary,
              onTrailing: () => context.push('/voice-rooms'),
            ),
            SizedBox(
              height: 196,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length.clamp(0, 12),
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _VoiceRoomCard(
                  room: items[i],
                  onJoin: () => context.push(
                    '/voice-room/${items[i].apiRoomKey}',
                    extra: items[i],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VoiceRoomCard extends StatelessWidget {
  const _VoiceRoomCard({required this.room, required this.onJoin});

  final VoiceRoomEntity room;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final count = room.displayOnline;

    return SizedBox(
      width: 168,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(HomePalette.radiusCard),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                HomePalette.primary.withValues(alpha: 0.55),
                HomePalette.darkBackground,
              ],
            ),
            border: Border.all(color: HomePalette.glassBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.icon ?? '🎙️',
                  style: const TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  room.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: context.colors.onSurface,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.people_rounded,
                      size: 14,
                      color: context.colors.onSurfaceMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (room.recentUserAvatars.isNotEmpty)
                      SizedBox(
                        width: 52,
                        height: 22,
                        child: Stack(
                          children: [
                            for (var i = 0; i < room.recentUserAvatars.length.clamp(0, 3); i++)
                              Positioned(
                                left: i * 14.0,
                                child: UserAvatar(
                                  url: room.recentUserAvatars[i],
                                  radius: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onJoin,
                    style: FilledButton.styleFrom(
                      backgroundColor: HomePalette.primary,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Katıl'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
