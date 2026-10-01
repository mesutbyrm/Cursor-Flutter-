import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/images/canlifal_network_image.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/discover_voice_rooms.dart';
import '../../../notifications/presentation/providers/notifications_providers.dart';
import '../../../voice_hub/presentation/utils/navigate_to_voice_room.dart';
import '../../domain/entities/social_discovery_user.dart';
import '../providers/social_discovery_providers.dart';
import 'tk_common.dart';
import 'tk_palette.dart';
import 'tk_providers.dart';

// ─────────────────────────────── Başlık ───────────────────────────────

class TanisKaynasHeader extends ConsumerWidget {
  const TanisKaynasHeader({
    super.key,
    required this.onSearch,
    required this.onNotifications,
    required this.onFilter,
    this.onBack,
  });

  final VoidCallback onSearch;
  final VoidCallback onNotifications;
  final VoidCallback onFilter;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = TkPalette.of(context);
    final unread = ref.watch(notificationsUnreadCountProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 4),
      child: Row(
        children: [
          if (onBack != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _CircleIcon(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack!,
                label: 'Geri',
              ),
            )
          else
            ShaderMask(
              shaderCallback: (r) => TkPalette.primaryGradient.createShader(r),
              child: const Icon(Icons.favorite_border_rounded,
                  color: Colors.white, size: 34),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Tanış ',
                          style: TextStyle(color: p.text),
                        ),
                        const TextSpan(
                          text: 'Kaynaş',
                          style: TextStyle(color: TkPalette.pink),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  'Yeni insanlarla tanış, sohbet et, arkadaşlıklar kur.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          _CircleIcon(icon: Icons.search_rounded, onTap: onSearch, label: 'Ara'),
          const SizedBox(width: 6),
          _CircleIcon(
            icon: Icons.notifications_none_rounded,
            onTap: onNotifications,
            badge: unread,
            label: 'Bildirimler',
          ),
          const SizedBox(width: 6),
          _CircleIcon(icon: Icons.tune_rounded, onTap: onFilter, label: 'Filtre'),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.icon,
    required this.onTap,
    required this.label,
    this.badge = 0,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String label;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    return TkPressable(
      onTap: onTap,
      semanticLabel: label,
      child: SizedBox(
        width: 42,
        height: 42,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.glass,
                border: Border.all(color: p.border),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: p.text, size: 21),
            ),
            if (badge > 0)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badge > 99 ? '99+' : '$badge',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── Kategori sekmeleri ───────────────────────────

class TanisKaynasCategoryTabs extends ConsumerWidget {
  const TanisKaynasCategoryTabs({super.key, required this.onSelected});

  final ValueChanged<TkCategory> onSelected;

  static const _items = <(TkCategory, String, IconData, Color)>[
    (TkCategory.forYou, 'Sana Özel', Icons.local_fire_department_rounded,
        TkPalette.amber),
    (TkCategory.online, 'Çevrimiçi', Icons.circle, TkPalette.online),
    (TkCategory.nearby, 'Yakınımda', Icons.location_on_rounded, TkPalette.pink),
    (TkCategory.interests, 'İlgi Alanları', Icons.grid_view_rounded,
        TkPalette.blue),
    (TkCategory.rooms, 'Tanışma Odaları', Icons.mic_rounded, TkPalette.purple),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(tkCategoryProvider);
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (cat, label, icon, color) = _items[i];
          return TkChip(
            label: label,
            icon: icon,
            iconColor: color,
            selected: cat == selected,
            onTap: () => onSelected(cat),
          );
        },
      ),
    );
  }
}

// ─────────────────────────── Şu an çevrimiçi ───────────────────────────

class OnlineUsersSection extends ConsumerWidget {
  const OnlineUsersSection({
    super.key,
    required this.onAddStory,
    required this.onOpenUser,
    required this.onSeeAll,
  });

  final VoidCallback onAddStory;
  final ValueChanged<SocialDiscoveryUser> onOpenUser;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = TkPalette.of(context);
    final async = ref.watch(tkOnlineUsersProvider);
    final total = async.valueOrNull?.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TkSectionHeader(
            title: 'Şu An Çevrimiçi',
            leading: const CircleAvatar(
              radius: 6,
              backgroundColor: TkPalette.online,
            ),
            trailingText: total != null ? '$total kişi çevrimiçi' : null,
            onTap: onSeeAll,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: async.when(
            loading: () => const _AvatarStripSkeleton(),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(tkOnlineUsersProvider),
                child: const Text('Çevrimiçi liste alınamadı · Tekrar dene'),
              ),
            ),
            data: (feed) {
              final users = feed.users;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: users.length + 1 + (users.isEmpty ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return _StoryAddItem(onTap: onAddStory);
                  }
                  if (users.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          'Şu an çevrimiçi kimse yok',
                          style: TextStyle(color: p.textFaint),
                        ),
                      ),
                    );
                  }
                  final u = users[i - 1];
                  return _OnlineAvatar(user: u, onTap: () => onOpenUser(u));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StoryAddItem extends StatelessWidget {
  const _StoryAddItem({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    return TkPressable(
      onTap: onTap,
      semanticLabel: 'Hikaye ekle',
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: p.textFaint, width: 1.4),
                color: p.glass,
              ),
              alignment: Alignment.center,
              child: Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: TkPalette.primaryGradient,
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hikayem',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.text, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineAvatar extends StatelessWidget {
  const _OnlineAvatar({required this.user, required this.onTap});

  final SocialDiscoveryUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    return TkPressable(
      onTap: onTap,
      semanticLabel: user.displayName,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2.5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: TkPalette.ringGradient,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.background,
                      ),
                      child: ClipOval(child: _Avatar(url: user.avatarUrl, size: 55)),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: TkPalette.online,
                        border: Border.all(color: p.background, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.text, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.size});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    final u = url?.trim() ?? '';
    if (u.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: const Color(0xFF2A2350),
        child: Icon(Icons.person_rounded, color: Colors.white54, size: size * 0.5),
      );
    }
    return CanlifalNetworkImage(
      url: u,
      width: size,
      height: size,
      fit: BoxFit.cover,
      thumbnailWidth: (size * 3).round(),
    );
  }
}

class _AvatarStripSkeleton extends StatelessWidget {
  const _AvatarStripSkeleton();

  @override
  Widget build(BuildContext context) {
    return TkShimmer(
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 6,
        itemBuilder: (_, _) => const SizedBox(
          width: 76,
          child: Column(
            children: [
              TkSkeletonBox(width: 62, height: 62, circle: true),
              SizedBox(height: 8),
              TkSkeletonBox(width: 46, height: 10),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Tanışma amacı ───────────────────────────

class MeetingPurposeSection extends ConsumerWidget {
  const MeetingPurposeSection({super.key});

  static const _icons = <String, (IconData, Color)>{
    'chat': (Icons.chat_bubble_rounded, TkPalette.blue),
    'friendship': (Icons.person_rounded, TkPalette.amber),
    'new_people': (Icons.favorite_rounded, TkPalette.pink),
    'gaming': (Icons.sports_esports_rounded, TkPalette.cyan),
    'music': (Icons.music_note_rounded, TkPalette.purple),
    'voice': (Icons.mic_rounded, TkPalette.purple),
    'travel': (Icons.flight_rounded, TkPalette.online),
    'relationship': (Icons.favorite_border_rounded, TkPalette.magenta),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(tkPurposeProvider);
    return TkGlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TkSectionHeader(
            title: 'Tanışma Amacın Nedir?',
            subtitle: 'Sana uygun kişileri gösterelim',
            leading: Icon(Icons.track_changes_rounded,
                color: TkPalette.pink, size: 24),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final purpose in tkPurposes)
                TkChip(
                  dense: true,
                  label: purpose.label,
                  icon: _icons[purpose.id]?.$1,
                  iconColor: _icons[purpose.id]?.$2,
                  selected: selected.contains(purpose.id),
                  onTap: () =>
                      ref.read(tkPurposeProvider.notifier).toggle(purpose.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Yakınımdaki insanlar ───────────────────────────

class NearbyUsersSection extends ConsumerWidget {
  const NearbyUsersSection({
    super.key,
    required this.users,
    required this.onOpenUser,
    required this.onEnableLocation,
    required this.onSeeAll,
    this.enablingLocation = false,
  });

  /// Keşif listesinden mesafe bandı olanlar (koordinat hiç gösterilmez).
  final List<SocialDiscoveryUser> users;
  final ValueChanged<SocialDiscoveryUser> onOpenUser;
  final VoidCallback onEnableLocation;
  final VoidCallback onSeeAll;
  final bool enablingLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = TkPalette.of(context);
    final location = ref.watch(userLocationSettingsProvider).valueOrNull;
    final enabled = location?.locationEnabled ?? false;
    return TkGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TkSectionHeader(
            title: 'Yakınımdaki İnsanlar',
            subtitle: enabled
                ? (users.isEmpty
                    ? 'Yakında henüz kimse yok'
                    : '${users.length} kişi yakında')
                : 'Konum kapalı',
            leading: const Icon(Icons.location_on_rounded,
                color: TkPalette.pink, size: 24),
            onTap: enabled && users.isNotEmpty ? onSeeAll : null,
          ),
          const SizedBox(height: 12),
          if (!enabled)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Yakındaki kişileri görmek için konum izni ver. '
                    'Tam konumun kimseye gösterilmez, yalnızca yaklaşık mesafe.',
                    style: TextStyle(color: p.textMuted, fontSize: 12.5),
                  ),
                ),
                const SizedBox(width: 10),
                TkGradientButton(
                  label: enablingLocation ? '…' : 'İzin Ver',
                  height: 38,
                  onTap: enablingLocation ? null : onEnableLocation,
                ),
              ],
            )
          else if (users.isEmpty)
            Text(
              'Yakınında konumunu açmış biri olduğunda burada görünür.',
              style: TextStyle(color: p.textMuted, fontSize: 12.5),
            )
          else
            SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: users.length.clamp(0, 12),
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final u = users[i];
                  return TkPressable(
                    onTap: () => onOpenUser(u),
                    semanticLabel: u.displayName,
                    child: SizedBox(
                      width: 92,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _Avatar(url: u.avatarUrl, size: 92),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (u.isOnline) ...[
                                const CircleAvatar(
                                  radius: 4,
                                  backgroundColor: TkPalette.online,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  u.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: p.text,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            u.distanceLabel ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(color: p.textFaint, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Ortak ilgi alanları ───────────────────────────

class SharedInterestsSection extends StatelessWidget {
  const SharedInterestsSection({
    super.key,
    required this.counts,
    required this.onTapInterest,
  });

  /// Yüklenen gerçek keşif listesinden sayılır.
  final List<({String hobby, int count})> counts;
  final ValueChanged<String> onTapInterest;

  static const _style = <String, (IconData, Color)>{
    'müzik': (Icons.headphones_rounded, TkPalette.pink),
    'futbol': (Icons.sports_soccer_rounded, TkPalette.online),
    'oyun': (Icons.sports_esports_rounded, TkPalette.purple),
    'film': (Icons.movie_rounded, TkPalette.amber),
    'kahve': (Icons.coffee_rounded, Color(0xFFB45309)),
    'kitap': (Icons.menu_book_rounded, TkPalette.blue),
    'gezi': (Icons.flight_rounded, TkPalette.cyan),
  };

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    return TkGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TkSectionHeader(
            title: 'Seninle Aynı Şeyleri Sevenler',
            leading:
                Icon(Icons.favorite_rounded, color: TkPalette.pink, size: 22),
          ),
          const SizedBox(height: 12),
          if (counts.isEmpty)
            Text(
              'Profiline ilgi alanı ekle; aynı şeyleri sevenleri burada gösterelim.',
              style: TextStyle(color: p.textMuted, fontSize: 12.5),
            )
          else
            LayoutBuilder(
              builder: (context, c) {
                final cols = c.maxWidth >= 360 ? 3 : 2;
                const gap = 8.0;
                final w = (c.maxWidth - gap * (cols - 1)) / cols;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final e in counts)
                      SizedBox(
                        width: w,
                        child: TkPressable(
                          onTap: () => onTapInterest(e.hobby),
                          semanticLabel: e.hobby,
                          child: _InterestTile(
                            label: e.hobby,
                            count: e.count,
                            icon: _style[e.hobby.toLowerCase()]?.$1 ??
                                Icons.tag_rounded,
                            color: _style[e.hobby.toLowerCase()]?.$2 ??
                                TkPalette.purple,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _InterestTile extends StatelessWidget {
  const _InterestTile({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  final String label;
  final int count;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = TkPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$count kişi',
                  maxLines: 1,
                  style: TextStyle(color: p.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Şimdi tanışıyorlar ───────────────────────────

class LiveRoomsSection extends ConsumerWidget {
  const LiveRoomsSection({super.key, required this.onSeeAll});

  final VoidCallback onSeeAll;

  static const _buttonGradients = <Gradient>[
    TkPalette.primaryGradient,
    TkPalette.ctaGradient,
    LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA855F7)]),
    LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF22C55E)]),
    LinearGradient(colors: [Color(0xFFDB2777), Color(0xFFC026D3)]),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = TkPalette.of(context);
    final async = ref.watch(voiceRoomsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TkSectionHeader(
            title: 'Şimdi Tanışıyorlar',
            subtitle: 'Canlı sesli odalara katıl, yeni insanlarla tanış',
            leading: const Icon(Icons.mic_rounded,
                color: TkPalette.pink, size: 24),
            onTap: onSeeAll,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 168,
          child: async.when(
            loading: () => TkShimmer(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: 4,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, _) =>
                    const TkSkeletonBox(width: 156, height: 168, radius: 20),
              ),
            ),
            error: (_, _) => Center(
              child: TextButton(
                onPressed: () => ref.invalidate(voiceRoomsProvider),
                child: const Text('Odalar alınamadı · Tekrar dene'),
              ),
            ),
            data: (rooms) {
              final live = rooms.where((r) => r.displayOnline > 0).toList()
                ..sort((a, b) => b.displayOnline.compareTo(a.displayOnline));
              if (live.isEmpty) {
                return Center(
                  child: Text(
                    'Şu an aktif sesli oda yok',
                    style: TextStyle(color: p.textFaint),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: live.length.clamp(0, 12),
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) => _RoomCard(
                  room: live[i],
                  gradient: _buttonGradients[i % _buttonGradients.length],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RoomCard extends ConsumerWidget {
  const _RoomCard({required this.room, required this.gradient});

  final VoiceRoomEntity room;
  final Gradient gradient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bg = room.backgroundImageUrl?.trim() ?? '';
    return SizedBox(
      width: 156,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bg.isNotEmpty)
              CanlifalNetworkImage(
                url: bg,
                width: 156,
                height: 168,
                fit: BoxFit.cover,
                thumbnailWidth: 400,
              )
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gradient.colors.first.withValues(alpha: 0.55),
                      const Color(0xFF14102E),
                    ],
                  ),
                ),
              ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000000), Color(0xE60B0A1E)],
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 3.5,
                      backgroundColor: TkPalette.online,
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.people_alt_rounded,
                        color: Colors.white, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '${room.displayOnline}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: TkGradientButton(
                      label: 'Odaya Katıl',
                      height: 36,
                      gradient: gradient,
                      onTap: () => navigateToVoiceRoom(
                        context,
                        ref,
                        room: room,
                        source: 'tanis_kaynas',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
