import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/network/api_exception.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/ui/premium/premium.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../live/domain/entities/voice_room_sort.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import '../../../../voice_hub/presentation/widgets/voice_room_grid_tile.dart';
import 'discover_section_header.dart';
import 'discover_voice_room_carousel_item.dart';

/// Ana sayfa sohbet odaları — tek sıra, yatay kaydırma + alt avatar şeridi.
class DiscoverVoiceOrbs extends ConsumerStatefulWidget {
  const DiscoverVoiceOrbs({super.key});

  @override
  ConsumerState<DiscoverVoiceOrbs> createState() => _DiscoverVoiceOrbsState();
}

class _DiscoverVoiceOrbsState extends ConsumerState<DiscoverVoiceOrbs> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(Duration.zero, () {
      if (!mounted) return;
      _scheduleRefresh();
    });
  }

  void _scheduleRefresh() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      ref.invalidate(voiceRoomsProvider);
      _scheduleRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
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
          height: 220,
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
        return _VoiceRoomsCarousel(
          rooms: sortVoiceRoomsByPopularity(list),
        );
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

class _VoiceRoomsCarousel extends StatelessWidget {
  const _VoiceRoomsCarousel({required this.rooms});

  final List<VoiceRoomEntity> rooms;

  @override
  Widget build(BuildContext context) {
    const tileH =
        DiscoverVoiceRoomCarouselItem.tileWidth /
            VoiceRoomGridTile.tileAspectRatio +
        6 +
        28;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DiscoverSectionHeader(
          title: 'Sohbet Odaları',
          actionLabel: 'Tüm Odalar',
          onAction: () => context.push('/voice-rooms'),
        ),
        SizedBox(
          height: tileH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rooms.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final room = rooms[i];
              return DiscoverVoiceRoomCarouselItem(
                room: room,
                onTap: () => context.push(
                  '/voice-room/${room.id}',
                  extra: room,
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
