import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/ui/platform_blur.dart';
import '../../../../../core/ui/premium_2026/liquid_glass.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../feed/presentation/widgets/discover_premium_2026/discover_premium_visual.dart';
import '../../../../../core/navigation/wallet_navigation.dart';
import '../../../../../core/performance/list_perf.dart';
import '../../../../../core/providers/auth_selectors.dart';
import '../../../../live/domain/entities/live_stream_entity.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import 'package:canlifal_social/features/vip_gold/domain/voice_room_access.dart';
import 'package:canlifal_social/features/vip_gold/presentation/theme/vip_gold_tokens.dart';
import '../../../../live/presentation/utils/open_live_stream.dart';
import '../../utils/open_voice_chat_room_flow.dart';
import '../../theme/voice_room_tokens.dart';
import 'voice_discover_2026.dart';

/// Keşfet — referans görsel (header, sekmeler, hikaye, banner, popüler, canlı, grid, VIP).
class VoiceDiscoverHub2026 extends ConsumerStatefulWidget {
  const VoiceDiscoverHub2026({
    super.key,
    required this.rooms,
    required this.liveStreams,
    required this.onRoomTap,
    required this.onSearchChanged,
    this.topPadding = 0,
  });

  final List<VoiceRoomEntity> rooms;
  final List<LiveStreamEntity> liveStreams;
  final ValueChanged<VoiceRoomEntity> onRoomTap;
  final ValueChanged<String> onSearchChanged;
  final double topPadding;

  @override
  ConsumerState<VoiceDiscoverHub2026> createState() =>
      _VoiceDiscoverHub2026State();
}

class _VoiceDiscoverHub2026State extends ConsumerState<VoiceDiscoverHub2026> {
  final _searchCtrl = TextEditingController();
  final _scroll = ScrollController();
  String _tab = 'discover';
  int _visibleRooms = ListPerf.defaultPageSize;

  static const _tabs = [
    _DiscoverTab(id: 'discover', label: 'Keşfet', icon: Icons.explore_rounded),
    _DiscoverTab(id: 'popular', label: 'Popüler', icon: Icons.local_fire_department_rounded),
    _DiscoverTab(id: 'live', label: 'Canlı', icon: Icons.live_tv_rounded),
    _DiscoverTab(id: 'vip', label: 'VIP', icon: Icons.workspace_premium_rounded),
    _DiscoverTab(id: 'game', label: 'Oyun', icon: Icons.sports_esports_rounded),
    _DiscoverTab(id: 'music', label: 'Müzik', icon: Icons.music_note_rounded),
    _DiscoverTab(id: 'pk', label: 'PK', icon: Icons.flash_on_rounded),
    _DiscoverTab(id: 'more', label: 'Daha Fazla', icon: Icons.more_horiz_rounded),
  ];

  static const _gridCats = [
    _GridCat('night', 'Gece Sohbeti', Icons.nightlight_round, Color(0xFF7C4DFF)),
    _GridCat('game', 'Oyun', Icons.sports_esports_rounded, Color(0xFF00E5C3)),
    _GridCat('music', 'Müzik', Icons.music_note_rounded, Color(0xFFFF2D7A)),
    _GridCat('fortune', 'Fal & Tarot', Icons.auto_awesome_rounded, Color(0xFFFFD54F)),
    _GridCat('pk', 'PK Odaları', Icons.flash_on_rounded, Color(0xFFB832FF)),
    _GridCat('fun', 'Eğlence', Icons.celebration_rounded, Color(0xFF5B8CFF)),
    _GridCat('social', 'Flört', Icons.favorite_rounded, Color(0xFFFF6B9D)),
    _GridCat('vip', 'VIP Odalar', Icons.lock_rounded, VipGoldTokens.goldMid),
  ];

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - ListPerf.preloadThresholdPx) {
      final total = _filtered.length;
      if (_visibleRooms < total) {
        setState(() {
          _visibleRooms = (_visibleRooms + ListPerf.defaultPageSize)
              .clamp(0, total);
        });
      }
    }
  }

  void _resetVisibleRooms() {
    _visibleRooms = ListPerf.defaultPageSize.clamp(0, _filtered.length);
  }

  List<VoiceRoomEntity> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = widget.rooms;
    if (q.isNotEmpty) {
      list = list
          .where(
            (r) =>
                r.displayTitle.toLowerCase().contains(q) ||
                r.slug.toLowerCase().contains(q) ||
                (r.ownerName?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    return switch (_tab) {
      'popular' => list..sort((a, b) => b.displayOnline.compareTo(a.displayOnline)),
      'vip' => list.where((r) => r.isVipGoldRoom).toList(),
      'pk' => list.where((r) {
        final t = '${r.nameTr} ${r.slug}'.toLowerCase();
        return t.contains('pk');
      }).toList(),
      'game' => list.where((r) {
        final t = '${r.nameTr} ${r.descTr ?? ''}'.toLowerCase();
        return t.contains('oyun');
      }).toList(),
      'music' => list.where((r) {
        final t = '${r.nameTr} ${r.descTr ?? ''}'.toLowerCase();
        return t.contains('müzik') || t.contains('music');
      }).toList(),
      'live' => list.where((r) => r.displayOnline > 0).toList(),
      _ => list,
    };
  }

  _DiscoverMetrics _metrics(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final compact = w < 360;
    final tablet = w >= 600;
    return _DiscoverMetrics(
      horizontalPad: tablet ? 24.0 : (compact ? 12.0 : 16.0),
      popularCardWidth: (w * 0.44).clamp(148.0, 200.0),
      popularRowHeight: tablet ? 240.0 : 220.0,
      bannerHeight: (w * 0.36).clamp(128.0, 168.0),
      gridColumns: tablet ? 4 : (w >= 400 ? 4 : 3),
      storiesHeight: tablet ? 116.0 : 108.0,
      sectionTitleSize: tablet ? 20.0 : 18.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _metrics(context);
    final coinBalance =
        (ref.watch(coinBalanceProvider).valueOrNull ??
            ref.watch(currentUserCoinBalanceProvider));
    final name = ref.watch(
      authControllerProvider.select((a) => a.valueOrNull?.display ?? 'Misafir'),
    );
    final avatar = ref.watch(
      authControllerProvider.select((a) => a.valueOrNull?.avatarUrl),
    );
    final vipRooms = widget.rooms.where((r) => r.isVipGoldRoom).take(8).toList();
    final popular = [...widget.rooms]
      ..sort((a, b) => b.displayOnline.compareTo(a.displayOnline));
    final live = widget.liveStreams.where((s) => s.isLive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: widget.topPadding),
        RepaintBoundary(
          child: _DiscoverHeader(
            userName: name,
            avatarUrl: avatar,
            coins: coinBalance ?? 0,
            horizontalPad: metrics.horizontalPad,
            onNotifications: () => context.push('/notifications'),
            onCoins: () => openJetonStore(context, ref: ref),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(metrics.horizontalPad, 12, metrics.horizontalPad, 0),
          child: _SearchBar(
            controller: _searchCtrl,
            onChanged: (v) {
              widget.onSearchChanged(v);
              setState(_resetVisibleRooms);
            },
          ),
        ),
        const SizedBox(height: 12),
        RepaintBoundary(
          child: SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPad),
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final t = _tabs[i];
                final active = _tab == t.id;
                return _TabChip(
                  tab: t,
                  active: active,
                  onTap: () {
                    if (t.id == 'vip') {
                      context.push('/vip-gold');
                      return;
                    }
                    if (t.id == 'pk' && widget.rooms.isNotEmpty) {
                      final r = widget.rooms.first;
                      context.push('/voice-room/${r.apiRoomKey}/pk', extra: r);
                      return;
                    }
                    setState(() {
                      _tab = t.id;
                      _resetVisibleRooms();
                    });
                  },
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        RepaintBoundary(
          child: _LiveStoriesRow(
            live: live,
            height: metrics.storiesHeight,
            horizontalPad: metrics.horizontalPad,
            onOpenRoom: () => showOpenVoiceChatRoomFlow(context, ref),
            onStreamTap: (s) => openLiveFromDiscover(context, ref, s),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            cacheExtent: ListPerf.cacheExtent,
            padding: EdgeInsets.fromLTRB(
              metrics.horizontalPad,
              16,
              metrics.horizontalPad,
              100,
            ),
            itemCount: _listChildCount(
              popular: popular,
              live: live,
              vipRooms: vipRooms,
            ),
            itemBuilder: (context, index) => _buildListChild(
              context,
              index: index,
              metrics: metrics,
              popular: popular,
              live: live,
              vipRooms: vipRooms,
            ),
          ),
        ),
      ],
    );
  }

  int _listChildCount({
    required List<VoiceRoomEntity> popular,
    required List<LiveStreamEntity> live,
    required List<VoiceRoomEntity> vipRooms,
  }) {
    var n = 8; // banner, titles, horizontals, grid, footer label
    final roomVisible = _visibleRooms.clamp(0, _filtered.length);
    return n + roomVisible + (_visibleRooms < _filtered.length ? 1 : 0);
  }

  Widget _buildListChild(
    BuildContext context, {
    required int index,
    required _DiscoverMetrics metrics,
    required List<VoiceRoomEntity> popular,
    required List<LiveStreamEntity> live,
    required List<VoiceRoomEntity> vipRooms,
  }) {
    var i = index;
    if (i == 0) {
      return _NightBanner(
        height: metrics.bannerHeight,
        onJoin: widget.rooms.isNotEmpty
            ? () => widget.onRoomTap(widget.rooms.first)
            : null,
      );
    }
    i--;
    if (i == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: _SectionTitle(
          title: 'Popüler Odalar',
          action: 'Tümü',
          fontSize: metrics.sectionTitleSize,
        ),
      );
    }
    i--;
    if (i == 0) {
      return SizedBox(
        height: metrics.popularRowHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: popular.take(10).length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, j) => _PopularRoomCard(
            room: popular[j],
            index: j,
            width: metrics.popularCardWidth,
            onTap: () => widget.onRoomTap(popular[j]),
          ),
        ),
      );
    }
    i--;
    if (i == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: _SectionTitle(
          title: 'Canlı Yayınlar',
          action: 'Tümü',
          fontSize: metrics.sectionTitleSize,
        ),
      );
    }
    i--;
    if (i == 0) {
      if (live.isEmpty) {
        return Text(
          'Şu an canlı yayın yok',
          style: TextStyle(color: context.colors.onSurfaceMuted.withValues(alpha: 0.9)),
        );
      }
      return SizedBox(
        height: 140,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: live.length.clamp(0, 12),
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, j) => _LiveStreamCard(
            stream: live[j],
            onTap: () => openLiveFromDiscover(context, ref, live[j]),
          ),
        ),
      );
    }
    i--;
    if (i == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: _SectionTitle(
          title: 'Kategoriler',
          action: null,
          fontSize: metrics.sectionTitleSize,
        ),
      );
    }
    i--;
    if (i == 0) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: metrics.gridColumns,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: metrics.gridColumns >= 4 ? 0.82 : 0.88,
        ),
        itemCount: _gridCats.length,
        itemBuilder: (context, j) {
          final c = _gridCats[j];
          final count = _roomCountForCat(c.id);
          return _CategoryIconTile(
            cat: c,
            roomLabel: count > 0 ? '${VoiceLiveHeader2026Format.count(count)} oda' : '—',
            onTap: () {
              if (c.id == 'vip') {
                context.push('/vip-gold');
              } else {
                setState(() {
                  _tab = c.id == 'night' ? 'discover' : c.id;
                  _resetVisibleRooms();
                });
              }
            },
          );
        },
      );
    }
    i--;
    if (vipRooms.isNotEmpty) {
      if (i == 0) {
        return Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 10),
          child: _SectionTitle(
            title: 'VIP Odalar',
            action: 'Tümü',
            fontSize: metrics.sectionTitleSize,
          ),
        );
      }
      i--;
      if (i == 0) {
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: vipRooms.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, j) => _VipRoomCard(
              room: vipRooms[j],
              onTap: () => widget.onRoomTap(vipRooms[j]),
            ),
          ),
        );
      }
      i--;
    }
    if (i == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 10),
        child: Text(
          'Tüm odalar · ${_filtered.length}',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
          ),
        ),
      );
    }
    i--;
    final roomIndex = i;
    final visible = _visibleRooms.clamp(0, _filtered.length);
    if (roomIndex < visible) {
      final r = _filtered[roomIndex];
      return ListPerf.repaint(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _CompactRoomRow(
            room: r,
            onTap: () => widget.onRoomTap(r),
          ),
        ),
      );
    }
    if (roomIndex == visible && _visibleRooms < _filtered.length) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  int _roomCountForCat(String id) {
    return switch (id) {
      'vip' => widget.rooms.where((r) => r.isVipGoldRoom).length,
      'pk' => widget.rooms.where((r) {
          final t = '${r.nameTr} ${r.slug}'.toLowerCase();
          return t.contains('pk');
        }).length,
      'game' => widget.rooms.where((r) {
          final t = '${r.nameTr} ${r.descTr ?? ''}'.toLowerCase();
          return t.contains('oyun');
        }).length,
      _ => (widget.rooms.length / 4).ceil(),
    };
  }
}

void openLiveFromDiscover(
  BuildContext context,
  WidgetRef ref,
  LiveStreamEntity stream,
) {
  openLiveStreamNative(context, ref, stream);
}

class _DiscoverMetrics {
  const _DiscoverMetrics({
    required this.horizontalPad,
    required this.popularCardWidth,
    required this.popularRowHeight,
    required this.bannerHeight,
    required this.gridColumns,
    required this.storiesHeight,
    required this.sectionTitleSize,
  });

  final double horizontalPad;
  final double popularCardWidth;
  final double popularRowHeight;
  final double bannerHeight;
  final int gridColumns;
  final double storiesHeight;
  final double sectionTitleSize;
}

class _DiscoverTab {
  const _DiscoverTab({required this.id, required this.label, required this.icon});
  final String id;
  final String label;
  final IconData icon;
}

class _GridCat {
  const _GridCat(this.id, this.label, this.icon, this.color);
  final String id;
  final String label;
  final IconData icon;
  final Color color;
}

class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader({
    required this.userName,
    required this.avatarUrl,
    required this.coins,
    required this.horizontalPad,
    required this.onNotifications,
    required this.onCoins,
  });

  final String userName;
  final String? avatarUrl;
  final int coins;
  final double horizontalPad;
  final VoidCallback onNotifications;
  final VoidCallback onCoins;

  @override
  Widget build(BuildContext context) {
    return SafeBackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: DiscoverPremiumVisual.glassBlur,
        sigmaY: DiscoverPremiumVisual.glassBlur,
      ),
      child: Container(
          padding: EdgeInsets.fromLTRB(horizontalPad, 8, horizontalPad - 4, 10),
          decoration: BoxDecoration(
            color: DiscoverPremiumVisual.glassFill,
            border: Border(
              bottom: BorderSide(color: DiscoverPremiumVisual.glassBorder),
            ),
          ),
          child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl!)
                    : null,
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      )
                    : null,
              ),
              Positioned(
                bottom: -4,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: VipGoldTokens.goldLuxury,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'VIP',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba, $userName 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'Premium keşfet',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.onSurfaceMuted.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCoins,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VipGoldTokens.goldMid.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.monetization_on_rounded,
                      size: 16, color: VipGoldTokens.goldMid),
                  const SizedBox(width: 4),
                  Text(
                    '${VoiceLiveHeader2026Format.count(coins)} +',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      borderRadius: BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
      blur: DiscoverPremiumVisual.glassBlur,
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.65)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Oda, kullanıcı veya kategori ara…',
                hintStyle: TextStyle(
                  color: context.colors.onSurfaceMuted.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Icon(Icons.tune_rounded, color: Colors.white.withValues(alpha: 0.45)),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({required this.tab, required this.active, required this.onTap});

  final _DiscoverTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: active ? DiscoverPremiumVisual.brandGradient : null,
            color: active ? null : DiscoverPremiumVisual.glassFill,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? DiscoverPremiumVisual.secondary.withValues(alpha: 0.35)
                  : DiscoverPremiumVisual.glassBorder,
            ),
            boxShadow: active ? DiscoverPremiumVisual.cardGlow(pressed: true) : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tab.icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                tab.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: active ? Colors.white : Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveStoriesRow extends StatelessWidget {
  const _LiveStoriesRow({
    required this.live,
    required this.height,
    required this.horizontalPad,
    required this.onOpenRoom,
    required this.onStreamTap,
  });

  final List<LiveStreamEntity> live;
  final double height;
  final double horizontalPad;
  final VoidCallback onOpenRoom;
  final ValueChanged<LiveStreamEntity> onStreamTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPad),
        children: [
          _StoryOpenRoom(onTap: onOpenRoom),
          const SizedBox(width: 12),
          for (final s in live.take(8)) ...[
            _StoryLiveItem(stream: s, onTap: () => onStreamTap(s)),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

class _StoryOpenRoom extends StatelessWidget {
  const _StoryOpenRoom({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: DiscoverPremiumVisual.brandGradient,
              boxShadow: DiscoverPremiumVisual.cardGlow(),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 6),
          const Text(
            'Oda Aç',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _StoryLiveItem extends StatelessWidget {
  const _StoryLiveItem({required this.stream, required this.onTap});

  final LiveStreamEntity stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = stream.streamerName ?? stream.title;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppThemeColors.liveRed, VoiceRoomTokens.neonPink],
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white12,
              backgroundImage: stream.thumbnailUrl != null &&
                      stream.thumbnailUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(stream.thumbnailUrl!)
                  : null,
              child: stream.thumbnailUrl == null || stream.thumbnailUrl!.isEmpty
                  ? Text(name.isNotEmpty ? name[0] : '?')
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppThemeColors.liveRed,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'LIVE',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 72,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            VoiceLiveHeader2026Format.count(stream.viewerCount),
            style: TextStyle(
              fontSize: 9,
              color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _NightBanner extends StatelessWidget {
  const _NightBanner({required this.height, required this.onJoin});

  final double height;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
        gradient: const LinearGradient(
          colors: [
            DiscoverPremiumVisual.primary,
            DiscoverPremiumVisual.backgroundMid,
          ],
        ),
        boxShadow: DiscoverPremiumVisual.cardGlow(),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Icon(
              Icons.mic_rounded,
              size: 120,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GECE MUHABBETİ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Premium sesli sohbet — hemen katıl',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: onJoin,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: VoiceRoomTokens.neonPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    'Hemen Katıl',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.action,
    this.fontSize = 18,
  });

  final String title;
  final String? action;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: fontSize),
        ),
        const Spacer(),
        if (action != null)
          Text(
            action!,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: DiscoverPremiumVisual.secondary.withValues(alpha: 0.95),
            ),
          ),
      ],
    );
  }
}

class _PopularRoomCard extends StatelessWidget {
  const _PopularRoomCard({
    required this.room,
    required this.index,
    required this.width,
    required this.onTap,
  });

  final VoiceRoomEntity room;
  final int index;
  final double width;
  final VoidCallback onTap;

  String get _badge => switch (index % 4) {
        0 => 'Sıcak',
        1 => 'VIP',
        2 => 'Gece',
        _ => 'Oyun',
      };

  Color get _badgeColor => switch (_badge) {
        'Sıcak' => AppThemeColors.liveRed,
        'VIP' => VipGoldTokens.goldMid,
        'Gece' => VoiceRoomTokens.neonPurple,
        _ => VoiceRoomTokens.neonBlue,
      };

  @override
  Widget build(BuildContext context) {
    final bg = room.backgroundImageUrl;
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
              color: DiscoverPremiumVisual.glassFill,
              boxShadow: DiscoverPremiumVisual.cardGlow(),
            ),
            child: ClipRRect(
              borderRadius:
                  BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (bg != null && bg.isNotEmpty)
                          CachedNetworkImage(imageUrl: bg, fit: BoxFit.cover)
                        else
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF4C1D95), Color(0xFF1E1033)],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _badgeColor.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _badge,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.displayTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.people_alt_rounded,
                                size: 12, color: AppThemeColors.onlineGreen),
                            const SizedBox(width: 4),
                            Text(
                              VoiceLiveHeader2026Format.count(room.displayOnline),
                              style: const TextStyle(fontSize: 10),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: VoiceRoomTokens.fabGradient,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Katıl',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveStreamCard extends StatelessWidget {
  const _LiveStreamCard({required this.stream, required this.onTap});

  final LiveStreamEntity stream;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = stream.streamerName ?? stream.title;
    return SizedBox(
      width: 200,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
              boxShadow: DiscoverPremiumVisual.cardGlow(
                color: AppThemeColors.liveRed,
              ),
            ),
            child: ClipRRect(
            borderRadius:
                BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (stream.thumbnailUrl != null && stream.thumbnailUrl!.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: stream.thumbnailUrl!,
                    fit: BoxFit.cover,
                  )
                else
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF2A1458), Color(0xFF0D0820)],
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppThemeColors.liveRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            VoiceLiveHeader2026Format.count(stream.viewerCount),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Müzik Keyfi 🎵',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}

class _CategoryIconTile extends StatelessWidget {
  const _CategoryIconTile({
    required this.cat,
    required this.roomLabel,
    required this.onTap,
  });

  final _GridCat cat;
  final String roomLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DiscoverPremiumVisual.glassFill,
            borderRadius: BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
            border: Border.all(color: DiscoverPremiumVisual.glassBorder),
            boxShadow: DiscoverPremiumVisual.cardGlow(color: cat.color),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(cat.icon, color: cat.color, size: 26),
              const SizedBox(height: 6),
              Text(
                cat.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                roomLabel,
                style: TextStyle(
                  fontSize: 8,
                  color: context.colors.onSurfaceMuted.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VipRoomCard extends StatelessWidget {
  const _VipRoomCard({required this.room, required this.onTap});

  final VoiceRoomEntity room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius:
                  BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
              boxShadow: DiscoverPremiumVisual.cardGlow(color: VipGoldTokens.goldMid),
              gradient: LinearGradient(
                colors: [
                  VipGoldTokens.goldDeep.withValues(alpha: 0.5),
                  const Color(0xFF1A1208),
                ],
              ),
              border: Border.all(color: VipGoldTokens.goldMid.withValues(alpha: 0.45)),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: VipGoldTokens.goldLuxury,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'VIP',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      room.isPasswordLockedRoom
                          ? Icons.lock_rounded
                          : Icons.workspace_premium_rounded,
                      color: VipGoldTokens.goldMid,
                      size: 18,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  room.displayTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  room.descTr ?? 'Özel üyelik odası',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${VoiceLiveHeader2026Format.count(room.displayOnline)} kullanıcı',
                  style: TextStyle(
                    fontSize: 10,
                    color: VipGoldTokens.goldMid.withValues(alpha: 0.95),
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

class _CompactRoomRow extends StatelessWidget {
  const _CompactRoomRow({required this.room, required this.onTap});

  final VoiceRoomEntity room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DiscoverPremiumVisual.glassFill,
            borderRadius:
                BorderRadius.circular(DiscoverPremiumVisual.cardRadius),
            border: Border.all(color: DiscoverPremiumVisual.glassBorder),
            boxShadow: DiscoverPremiumVisual.cardGlow(),
          ),
          child: Row(
            children: [
              Text(room.icon ?? '🎤', style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${VoiceLiveHeader2026Format.count(room.displayOnline)} çevrimiçi',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}
