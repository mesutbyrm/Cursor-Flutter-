import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../live/domain/entities/live_stream_entity.dart';
import '../../../../live/domain/entities/voice_room_entity.dart';
import '../../../../profile/presentation/providers/profile_providers.dart';
import '../../../../vip_gold/domain/voice_room_access.dart';
import '../../../../vip_gold/presentation/theme/vip_gold_tokens.dart';
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
  String _tab = 'discover';

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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final coins = ref.watch(coinBalanceProvider).valueOrNull ?? user?.coinBalance ?? 0;
    final name = user?.display ?? 'Misafir';
    final avatar = user?.avatarUrl;
    final vipRooms = widget.rooms.where((r) => r.isVipGoldRoom).take(8).toList();
    final popular = [...widget.rooms]
      ..sort((a, b) => b.displayOnline.compareTo(a.displayOnline));
    final live = widget.liveStreams.where((s) => s.isLive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: widget.topPadding),
        _DiscoverHeader(
          userName: name,
          avatarUrl: avatar,
          coins: coins,
          onNotifications: () => context.push('/notifications'),
          onCoins: () => context.push('/jeton-store'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _SearchBar(
            controller: _searchCtrl,
            onChanged: (v) {
              widget.onSearchChanged(v);
              setState(() {});
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                  setState(() => _tab = t.id);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _LiveStoriesRow(
          live: live,
          onOpenRoom: () => showOpenVoiceChatRoomFlow(context, ref),
          onStreamTap: (s) => openLiveFromDiscover(context, ref, s),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              _NightBanner(
                onJoin: widget.rooms.isNotEmpty
                    ? () => widget.onRoomTap(widget.rooms.first)
                    : null,
              ),
              const SizedBox(height: 22),
              _SectionTitle(title: 'Popüler Odalar', action: 'Tümü'),
              const SizedBox(height: 10),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: popular.take(10).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => _PopularRoomCard(
                    room: popular[i],
                    index: i,
                    onTap: () => widget.onRoomTap(popular[i]),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _SectionTitle(title: 'Canlı Yayınlar', action: 'Tümü'),
              const SizedBox(height: 10),
              if (live.isEmpty)
                Text(
                  'Şu an canlı yayın yok',
                  style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.9)),
                )
              else
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: live.length.clamp(0, 12),
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => _LiveStreamCard(
                      stream: live[i],
                      onTap: () => openLiveFromDiscover(context, ref, live[i]),
                    ),
                  ),
                ),
              const SizedBox(height: 22),
              _SectionTitle(title: 'Kategoriler', action: null),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                itemCount: _gridCats.length,
                itemBuilder: (context, i) {
                  final c = _gridCats[i];
                  final count = _roomCountForCat(c.id);
                  return _CategoryIconTile(
                    cat: c,
                    roomLabel: count > 0 ? '${VoiceLiveHeader2026Format.count(count)} oda' : '—',
                    onTap: () {
                      if (c.id == 'vip') {
                        context.push('/vip-gold');
                      } else {
                        setState(() => _tab = c.id == 'night' ? 'discover' : c.id);
                      }
                    },
                  );
                },
              ),
              if (vipRooms.isNotEmpty) ...[
                const SizedBox(height: 22),
                _SectionTitle(title: 'VIP Odalar', action: 'Tümü'),
                const SizedBox(height: 10),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: vipRooms.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) => _VipRoomCard(
                      room: vipRooms[i],
                      onTap: () => widget.onRoomTap(vipRooms[i]),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Tüm odalar · ${_filtered.length}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMuted.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 10),
              ..._filtered.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CompactRoomRow(
                    room: r,
                    onTap: () => widget.onRoomTap(r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
    required this.onNotifications,
    required this.onCoins,
  });

  final String userName;
  final String? avatarUrl;
  final int coins;
  final VoidCallback onNotifications;
  final VoidCallback onCoins;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
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
                    color: AppColors.textMuted.withValues(alpha: 0.95),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.5)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Oda, kullanıcı veya kategori ara…',
                hintStyle: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.85),
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
            gradient: active ? VoiceRoomTokens.fabGradient : null,
            color: active ? null : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.12),
            ),
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
    required this.onOpenRoom,
    required this.onStreamTap,
  });

  final List<LiveStreamEntity> live;
  final VoidCallback onOpenRoom;
  final ValueChanged<LiveStreamEntity> onStreamTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
              gradient: VoiceRoomTokens.fabGradient,
              boxShadow: VoiceRoomTokens.neonGlow(VoiceRoomTokens.neonPurple),
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
                colors: [AppColors.liveRed, VoiceRoomTokens.neonPink],
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
              color: AppColors.liveRed,
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
              color: AppColors.textMuted.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _NightBanner extends StatelessWidget {
  const _NightBanner({required this.onJoin});
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF5B2D9E), Color(0xFF1A0B3D)],
        ),
        boxShadow: VoiceRoomTokens.neonGlow(VoiceRoomTokens.neonPurple, blur: 18),
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
  const _SectionTitle({required this.title, this.action});

  final String title;
  final String? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        const Spacer(),
        if (action != null)
          Text(
            action!,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.95),
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
    required this.onTap,
  });

  final VoiceRoomEntity room;
  final int index;
  final VoidCallback onTap;

  String get _badge => switch (index % 4) {
        0 => 'Sıcak',
        1 => 'VIP',
        2 => 'Gece',
        _ => 'Oyun',
      };

  Color get _badgeColor => switch (_badge) {
        'Sıcak' => AppColors.liveRed,
        'VIP' => VipGoldTokens.goldMid,
        'Gece' => VoiceRoomTokens.neonPurple,
        _ => VoiceRoomTokens.neonBlue,
      };

  @override
  Widget build(BuildContext context) {
    final bg = room.backgroundImageUrl;
    return SizedBox(
      width: 160,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.06),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
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
                                size: 12, color: AppColors.onlineGreen),
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
          borderRadius: BorderRadius.circular(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
                              color: AppColors.liveRed,
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
                  color: AppColors.textMuted.withValues(alpha: 0.85),
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
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: VoiceRoomTokens.glassCard(radius: 14),
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
                        color: AppColors.textMuted.withValues(alpha: 0.9),
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
