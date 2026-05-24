import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/discover_tab_layout.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../live/domain/entities/voice_room_sort.dart';
import '../../live/presentation/providers/live_providers.dart';
import 'widgets/premium/voice_discover_header.dart';
import 'widgets/voice_room_grid_tile.dart';

/// Sesli sohbet keşfet — arama, kategoriler, oda grid.
class VoiceRoomsBody extends ConsumerStatefulWidget {
  const VoiceRoomsBody({
    super.key,
    this.embeddedInLiveShellTab = false,
  });

  final bool embeddedInLiveShellTab;

  @override
  ConsumerState<VoiceRoomsBody> createState() => _VoiceRoomsBodyState();
}

class _VoiceRoomsBodyState extends ConsumerState<VoiceRoomsBody> {
  final _searchCtrl = TextEditingController();
  var _category = 'Tümü';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<VoiceRoomEntity> _filter(List<VoiceRoomEntity> rooms) {
    final q = _searchCtrl.text.trim().toLowerCase();
    var out = rooms;
    if (q.isNotEmpty) {
      out = out
          .where(
            (r) =>
                r.displayTitle.toLowerCase().contains(q) ||
                r.slug.toLowerCase().contains(q) ||
                (r.ownerName?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    switch (_category) {
      case 'Popüler':
        out = [...out]..sort((a, b) => b.displayOnline.compareTo(a.displayOnline));
      case 'Müzik':
        out = out
            .where((r) {
              final t = _tags(r);
              return t.contains('müzik') || t.contains('music');
            })
            .toList();
      case 'Oyun':
        out = out
            .where((r) {
              final t = _tags(r);
              return t.contains('oyun') || t.contains('game');
            })
            .toList();
      case 'Sohbet':
        out = out
            .where((r) {
              final t = _tags(r);
              return t.contains('sohbet') || t.contains('chat');
            })
            .toList();
    }
    return out;
  }

  String _tags(VoiceRoomEntity r) {
    return '${r.nameTr} ${r.descTr ?? ''} ${r.slug}'.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
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
        final filtered = _filter(ordered);
        final mq = MediaQuery.paddingOf(context);
        final topPad = widget.embeddedInLiveShellTab
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
                  child: VoiceDiscoverHeader(
                    searchController: _searchCtrl,
                    selectedCategory: _category,
                    onCategory: (c) => setState(() => _category = c),
                    onSearchChanged: (_) => setState(() {}),
                    roomCount: filtered.length,
                  ),
                ),
              ),
              if (filtered.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: DiscoverEmptyState(
                    icon: Icons.search_off_rounded,
                    message: 'Aramanıza uygun oda bulunamadı.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 100),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: VoiceRoomGridTile.crossAxisCount,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: VoiceRoomGridTile.tileAspectRatio,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final r = filtered[i];
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

  static List<VoiceRoomEntity> _orderedRooms(
    List<VoiceRoomEntity> all,
    VoiceRoomEntity? mine,
  ) {
    final sorted = sortVoiceRoomsByPopularity(all);
    if (mine == null) return sorted;
    final rest = sorted.where((r) => r.id != mine.id).toList();
    return [mine, ...rest];
  }

  static void _openRoom(BuildContext context, VoiceRoomEntity room) {
    context.push('/voice-room/${room.id}', extra: room);
  }
}
