import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/ui/premium/premium_skeleton.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/domain/entities/voice_room_sort.dart';
import '../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import '../../../voice_hub/presentation/widgets/voice_room_grid_tile.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';
import 'home_section_header.dart';

/// Sesli sohbet — 4 sütunlu oda grid'i (canlifal.com ana sayfa §3.3).
class HomeVoiceRoomsRow extends ConsumerWidget {
  const HomeVoiceRoomsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.useNextAuth) {
      return _section(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Sesli odalar için giriş yapın.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ),
      );
    }

    final rooms = ref.watch(homeVoiceRoomsProvider);

    return rooms.when(
      loading: () => _section(child: _LoadingGrid()),
      error: (e, _) => _section(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            ApiException.userMessage(e),
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
      data: (items) => _section(
        child: _VoiceRoomsGrid(
          rooms: sortVoiceRoomsByPopularity(items),
        ),
      ),
    );
  }

  Widget _section({required Widget child}) {
    return Builder(
      builder: (context) => Column(
        children: [
          HomeSectionHeader(
            title: 'Sesli Sohbet',
            leadingDotColor: HomePalette.secondary,
            onTrailing: () => context.push('/voice-rooms'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: child,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = VoiceRoomGridTile.crossAxisCount;
        const spacing = 8.0;
        final tileW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        final tileH = tileW / VoiceRoomGridTile.tileAspectRatio;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(
            8,
            (_) => PremiumSkeleton(
              width: tileW,
              height: tileH,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
          ),
        );
      },
    );
  }
}

class _VoiceRoomsGrid extends ConsumerWidget {
  const _VoiceRoomsGrid({required this.rooms});

  final List<VoiceRoomEntity> rooms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rooms.isEmpty) {
      return Text(
        'Şu an açık sohbet odası yok.',
        style: TextStyle(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.65),
        ),
      );
    }

    final preview = rooms.take(8).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        const cols = VoiceRoomGridTile.crossAxisCount;
        const spacing = 8.0;
        final tileW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
        final tileH = tileW / VoiceRoomGridTile.tileAspectRatio;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final room in preview)
              SizedBox(
                width: tileW,
                height: tileH,
                child: VoiceRoomGridTile(
                  room: room,
                  onTap: () => openVoiceRoomWithVipGate(context, ref, room),
                ),
              ),
          ],
        );
      },
    );
  }
}
