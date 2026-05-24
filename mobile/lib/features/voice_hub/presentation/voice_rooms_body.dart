import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/premium_2026/premium_immersive_background.dart';
import '../../../core/widgets/discover_tab_layout.dart';
import '../../live/domain/entities/voice_room_entity.dart';
import '../../live/domain/entities/voice_room_sort.dart';
import '../../live/presentation/providers/live_providers.dart';
import 'theme/voice_room_tokens.dart';
import 'pages/voice_gold_vip_page.dart';
import 'widgets/premium_2026/voice_discover_2026.dart';
import 'widgets/premium/voice_glass.dart';
import 'widgets/voice_room_grid_tile.dart';

/// Sesli sohbet keşfet — Premium 2026 kategoriler + öne çıkan + grid.
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
  String? _categoryId;

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
    if (_categoryId != null) {
      out = out.where((r) => _matchesCategory(r, _categoryId!)).toList();
    }
    return out;
  }

  bool _matchesCategory(VoiceRoomEntity r, String catId) {
    final t = '${r.nameTr} ${r.descTr ?? ''} ${r.slug}'.toLowerCase();
    switch (catId) {
      case 'fortune':
        return t.contains('fal') || t.contains('tarot') || t.contains('spirit');
      case 'game':
        return t.contains('oyun') || t.contains('game');
      case 'pk':
        return t.contains('pk') || t.contains('savaş');
      case 'vip':
        return t.contains('vip') || t.contains('gold');
      case 'social':
        return t.contains('sohbet') || t.contains('topluluk');
      case 'entertainment':
      default:
        return true;
    }
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

        return PremiumImmersiveBackground(
          child: RefreshIndicator(
            color: VoiceRoomTokens.neonPink,
            backgroundColor: VoiceRoomTokens.bgCosmic,
            onRefresh: () async => ref.invalidate(voiceRoomsProvider),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(16, topPad, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VoiceGlass(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          borderRadius: VoiceRoomTokens.radiusCard,
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: (_) => setState(() {}),
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Oda veya kullanıcı ara…',
                              hintStyle: TextStyle(
                                color: AppColors.textMuted.withValues(alpha: 0.9),
                              ),
                              border: InputBorder.none,
                              icon: Icon(
                                Icons.search_rounded,
                                color: VoiceRoomTokens.neonBlue.withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        VoiceDiscoverCategories2026(
                          selectedId: _categoryId,
                          onCategoryTap: (id) {
                            if (id == 'pk' && ordered.isNotEmpty) {
                              final r = ordered.first;
                              context.push('/voice-room/${r.apiRoomKey}/pk', extra: r);
                              return;
                            }
                            setState(() {
                              _categoryId = _categoryId == id ? null : id;
                            });
                          },
                        ),
                        VoiceFeaturedRooms2026(
                          rooms: ordered,
                          onRoomTap: (r) => _openRoom(context, r),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tüm odalar · ${filtered.length}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textMuted.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
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
    if (_isVipRoom(room)) {
      VoiceGoldVipPage.show(
        context,
        room: room,
        onJoinRoom: () => context.push(
          '/voice-room/${room.apiRoomKey}',
          extra: room,
        ),
      );
      return;
    }
    context.push('/voice-room/${room.apiRoomKey}', extra: room);
  }

  static bool _isVipRoom(VoiceRoomEntity room) {
    final t = '${room.nameTr} ${room.slug} ${room.descTr ?? ''}'.toLowerCase();
    return t.contains('vip') || t.contains('gold');
  }
}
