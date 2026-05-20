import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/ui/premium/premium.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import '../../../../voice_hub/presentation/widgets/voice_room_grid_tile.dart';
import 'discover_section_header.dart';

/// Ana sayfa sesli odalar — API, tam genişlik 4 sütun.
class DiscoverVoiceOrbs extends ConsumerWidget {
  const DiscoverVoiceOrbs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.useNextAuth) {
      return const _VoiceRoomsSection(
        child: PremiumEmptyHint(
          message: 'Sesli odalar için canlifal.com oturumu gerekir.',
        ),
      );
    }

    final rooms = ref.watch(voiceRoomsProvider);
    return rooms.when(
      loading: () => const _VoiceRoomsSection(
        child: SizedBox(
          height: 160,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accentPink,
              ),
            ),
          ),
        ),
      ),
      error: (e, _) => _VoiceRoomsSection(
        child: PremiumEmptyHint(
          message: ApiException.userMessage(e),
          onRetry: () => ref.invalidate(voiceRoomsProvider),
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const _VoiceRoomsSection(
            child: PremiumEmptyHint(
              message: 'Şu an açık sohbet odası yok.',
            ),
          );
        }
        return _VoiceRoomsGrid(rooms: list);
      },
    );
  }
}

class _VoiceRoomsSection extends StatelessWidget {
  const _VoiceRoomsSection({required this.child});

  final Widget child;

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
        child,
        const SizedBox(height: 12),
      ],
    );
  }
}

class _VoiceRoomsGrid extends StatelessWidget {
  const _VoiceRoomsGrid({required this.rooms});

  final List<VoiceRoomEntity> rooms;

  @override
  Widget build(BuildContext context) {
    const crossCount = VoiceRoomGridTile.crossAxisCount;
    const spacing = 10.0;
    const aspect = 0.78;

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final tileWidth =
                  (width - spacing * (crossCount - 1)) / crossCount;
              final tileHeight = tileWidth / aspect;
              final rows = (rooms.length / crossCount).ceil();
              final gridHeight =
                  rows * tileHeight + (rows > 1 ? (rows - 1) * spacing : 0);

              return SizedBox(
                height: gridHeight,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: aspect,
                  ),
                  itemCount: rooms.length,
                  itemBuilder: (ctx, i) {
                    final room = rooms[i];
                    return VoiceRoomGridTile(
                      room: room,
                      onTap: () => context.push(
                        '/voice-room/${room.id}',
                        extra: room,
                      ),
                    );
                  },
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
