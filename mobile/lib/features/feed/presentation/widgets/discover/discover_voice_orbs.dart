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
import '../../../../vip_gold/presentation/utils/open_voice_room_vip.dart';
import '../../../../voice_hub/presentation/widgets/voice_room_grid_tile.dart';
import 'discover_section_header.dart';

/// Ana sayfa sohbet odaları — 4 sütunlu grid (canlifal.com ana sayfa).
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
    final rooms = ref.watch(voiceRoomsProvider);
    if (!Env.useNextAuth) {
      return _VoiceRoomsSection(
        child: PremiumEmptyHint(
          message: 'Sesli odalar için giriş yapın.',
          onRetry: () => context.push('/login'),
        ),
      );
    }
    return rooms.when(
      loading: () => const _VoiceRoomsSection(
        child: SizedBox(
          height: 200,
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
        return _VoiceRoomsGrid(
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _VoiceRoomsGrid extends ConsumerWidget {
  const _VoiceRoomsGrid({required this.rooms});

  final List<VoiceRoomEntity> rooms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = rooms.take(8).toList();

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
              const cols = VoiceRoomGridTile.crossAxisCount;
              const spacing = 8.0;
              final tileW =
                  (constraints.maxWidth - spacing * (cols - 1)) / cols;
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
                        onTap: () => openVoiceRoomWithVipGate(
                          context,
                          ref,
                          room,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
