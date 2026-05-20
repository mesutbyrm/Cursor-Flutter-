import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/discover_tab_layout.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../live/presentation/providers/live_providers.dart';
import 'widgets/voice_room_grid_tile.dart';

/// Sesli sohbet — tüm odalar 4 sütunlu grid.
class VoiceRoomsBody extends ConsumerWidget {
  const VoiceRoomsBody({
    super.key,
    this.embeddedInLiveShellTab = false,
  });

  final bool embeddedInLiveShellTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.useNextAuth) {
      return const DiscoverEmptyState(
        icon: Icons.headset_mic_outlined,
        message:
            'Bu özellik canlifal.com oturumu ile kullanılabilir.\nGiriş yaptıktan sonra odalar burada listelenir.',
      );
    }

    final rooms = ref.watch(voiceRoomsProvider);
    final myRoom = ref.watch(myVoiceRoomProvider);

    return rooms.when(
      loading: () => const DiscoverAccentLoader(),
      error: (e, _) => DiscoverEmptyState(
        icon: Icons.mic_off_rounded,
        message: ApiException.userMessage(e),
        actionLabel: 'Yenile',
        action: () => ref.invalidate(voiceRoomsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const DiscoverEmptyState(
            icon: Icons.nights_stay_rounded,
            message: 'Henüz oda yok.\nYeni sesli sohbet odaları burada görünecek.',
          );
        }

        final ordered = _orderedRooms(list, myRoom);
        final mq = MediaQuery.paddingOf(context);
        final topPad = embeddedInLiveShellTab
            ? 8.0
            : mq.top + kToolbarHeight + 4;

        return RefreshIndicator(
          color: AppColors.accentPink,
          backgroundColor: AppColors.bgPurpleGlow,
          onRefresh: () async => ref.invalidate(voiceRoomsProvider),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(12, topPad, 12, 8),
                sliver: SliverToBoxAdapter(
                  child: _RoomsHeader(count: ordered.length),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 100),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: VoiceRoomGridTile.crossAxisCount,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: ordered.length,
                  itemBuilder: (context, i) {
                    final r = ordered[i];
                    final mine = myRoom != null && r.id == myRoom.id;
                    return VoiceRoomGridTile(
                      room: r,
                      isMine: mine,
                      onTap: () => _openRoom(context, r),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Benim oda en üstte, sonra diğer tüm odalar.
  static List<VoiceRoomEntity> _orderedRooms(
    List<VoiceRoomEntity> all,
    VoiceRoomEntity? mine,
  ) {
    if (mine == null) return List<VoiceRoomEntity>.from(all);
    final rest = all.where((r) => r.id != mine.id).toList();
    return [mine, ...rest];
  }

  static void _openRoom(BuildContext context, VoiceRoomEntity room) {
    context.push('/voice-room/${room.id}', extra: room);
  }
}

class _RoomsHeader extends StatelessWidget {
  const _RoomsHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [AppColors.accentCyan, AppColors.accentPink],
                ).createShader(b),
                child: const Text(
                  'Sesli sohbet odaları',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tüm odalar · satırda 4 oda',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.95),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accentPurple.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentPurple.withValues(alpha: 0.45),
            ),
          ),
          child: Text(
            '$count oda',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: AppColors.accentCyan,
            ),
          ),
        ),
      ],
    );
  }
}
