import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';

// ---------------------------------------------------------------------------
// Canlı yayın şeridi (büyük kartlar)
// ---------------------------------------------------------------------------
class HomeLiveStrip extends ConsumerWidget {
  const HomeLiveStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveStreamsProvider);
    return live.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (streams) {
        final onAir = streams.where((s) => s.isLive).toList();
        if (onAir.isEmpty) return const _EmptyLiveStrip();
        return SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: onAir.length > 10 ? 10 : onAir.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) => _LiveCard(stream: onAir[i]),
          ),
        );
      },
    );
  }
}

class _EmptyLiveStrip extends StatelessWidget {
  const _EmptyLiveStrip();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final names = ['Yayıncı 1', 'Yayıncı 2', 'Yayıncı 3'];
          final categories = ['Müzik · Sohbet', 'Gece Yayını', 'Eğlence'];
          final viewers = [4892, 3246, 2753];
          final colors = [
            [const Color(0xFF2D1B4E), const Color(0xFF1A0A2E)],
            [const Color(0xFF0A2E1A), const Color(0xFF0D0D1A)],
            [const Color(0xFF2E1A0A), const Color(0xFF1A0D0D)],
          ];
          return _PlaceholderLiveCard(
            name: names[i],
            category: categories[i],
            viewerCount: viewers[i],
            gradientColors: colors[i],
          );
        },
      ),
    );
  }
}

class _PlaceholderLiveCard extends StatelessWidget {
  const _PlaceholderLiveCard({
    required this.name,
    required this.category,
    required this.viewerCount,
    required this.gradientColors,
  });

  final String name;
  final String category;
  final int viewerCount;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Container(
                alignment: Alignment.center,
                child: Icon(Icons.person_rounded,
                    size: 60, color: Colors.white.withValues(alpha: 0.15)),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
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
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _MiniAvatarStack(count: 3),
                    const SizedBox(width: 6),
                    Text(
                      '+$viewerCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.signal_cellular_alt_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.6)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.stream});

  final LiveStreamEntity stream;

  void _open(BuildContext context) {
    if (!stream.isLive) return;
    context.push(
      CanlifalWebRoute.location(
        relativePath: '/sohbet/video?watch=${stream.id}',
        title: stream.title,
        streamIdForGifts: stream.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        width: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppTheme.surfaceElevated,
          border: Border.all(color: Colors.white10),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: stream.thumbnailUrl != null &&
                        stream.thumbnailUrl!.isNotEmpty
                    ? Image.network(
                        stream.thumbnailUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppTheme.surface,
                          alignment: Alignment.center,
                          child: const Icon(Icons.live_tv_rounded,
                              color: AppTheme.accent, size: 40),
                        ),
                      )
                    : Container(
                        color: AppTheme.surface,
                        alignment: Alignment.center,
                        child: const Icon(Icons.live_tv_rounded,
                            color: AppTheme.accent, size: 40),
                      ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
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
                    stream.streamerName ?? 'Yayıncı',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stream.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.visibility_rounded,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(
                        '${stream.viewerCount}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.signal_cellular_alt_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.6)),
                    ],
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

class _MiniAvatarStack extends StatelessWidget {
  const _MiniAvatarStack({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14.0 * count + 6,
      height: 20,
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: i * 10.0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: [
                  const Color(0xFF7B2FBE),
                  const Color(0xFFFE2C55),
                  const Color(0xFF25F4EE),
                ][i % 3],
                border: Border.all(color: AppTheme.background, width: 1.5),
              ),
              child: Icon(Icons.person, size: 12,
                  color: Colors.white.withValues(alpha: 0.8)),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hızlı İşlemler
// ---------------------------------------------------------------------------
class HomeQuickActions extends StatelessWidget {
  const HomeQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Hızlı İşlemler',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Text(
                'Tümünü gör',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.muted.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                _QuickActionChip(
                  icon: Icons.videocam_rounded,
                  label: 'Canlı Yayın\nBaşlat',
                  color: Color(0xFFFE2C55),
                  bgColor: Color(0xFF2E0A14),
                ),
                SizedBox(width: 10),
                _QuickActionChip(
                  icon: Icons.graphic_eq_rounded,
                  label: 'Sesli Odaya\nGir',
                  color: Color(0xFF7B2FBE),
                  bgColor: Color(0xFF1A0A2E),
                ),
                SizedBox(width: 10),
                _QuickActionChip(
                  icon: Icons.group_add_rounded,
                  label: 'Arkadaşlarını\nDavet Et',
                  color: Color(0xFFFF7043),
                  bgColor: Color(0xFF2E1A0A),
                ),
                SizedBox(width: 10),
                _QuickActionChip(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Hediye\nYolla',
                  color: Color(0xFF66BB6A),
                  bgColor: Color(0xFF0A2E14),
                ),
                SizedBox(width: 10),
                _QuickActionChip(
                  icon: Icons.diamond_rounded,
                  label: 'Jeton\nYükle',
                  color: Color(0xFF42A5F5),
                  bgColor: Color(0xFF0A142E),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sohbet Odaları
// ---------------------------------------------------------------------------
class HomeChatRooms extends ConsumerWidget {
  const HomeChatRooms({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.useNextAuth) return const SizedBox.shrink();
    final rooms = ref.watch(voiceRoomsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Sohbet Odaları',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/voice-rooms'),
                child: Text(
                  'Tüm Odalar',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.muted.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          rooms.when(
            loading: () => const SizedBox(
              height: 110,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (list) {
              if (list.isEmpty) return const _PlaceholderChatRooms();
              return SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) => _ChatRoomCard(room: list[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlaceholderChatRooms extends StatelessWidget {
  const _PlaceholderChatRooms();

  @override
  Widget build(BuildContext context) {
    final rooms = [
      ('🎵', 'Müzik Keyfi', 12, const Color(0xFF7B2FBE)),
      ('💬', 'Gece Sohbeti', 8, const Color(0xFFFE2C55)),
      ('🌟', 'Yıldızların Altında', 15, const Color(0xFFFFD54F)),
      ('☕', 'Kahve Molası', 5, const Color(0xFFFF7043)),
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: rooms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final (emoji, name, count, color) = rooms[i];
          return _PlaceholderRoomCard(
            emoji: emoji,
            name: name,
            onlineCount: count,
            accentColor: color,
          );
        },
      ),
    );
  }
}

class _PlaceholderRoomCard extends StatelessWidget {
  const _PlaceholderRoomCard({
    required this.emoji,
    required this.name,
    required this.onlineCount,
    required this.accentColor,
  });

  final String emoji;
  final String name;
  final int onlineCount;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 105,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.2),
            const Color(0xFF14141C),
          ],
        ),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_rounded,
                        size: 11,
                        color: Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 3),
                    Text(
                      '$onlineCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            '$onlineCount kişi',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.muted.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatRoomCard extends StatelessWidget {
  const _ChatRoomCard({required this.room});

  final VoiceRoomEntity room;

  void _open(BuildContext context) {
    context.push(
      CanlifalWebRoute.location(
        relativePath: '/sohbet/${room.slug}',
        title: room.nameTr,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        width: 105,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.cosmicPurple.withValues(alpha: 0.2),
              const Color(0xFF14141C),
            ],
          ),
          border: Border.all(
            color: AppTheme.cosmicPurple.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(room.icon ?? '💬', style: const TextStyle(fontSize: 28)),
                const Spacer(),
                if (room.onlineCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_rounded,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 3),
                        Text(
                          '${room.onlineCount}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              room.nameTr,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const Spacer(),
            Text(
              '${room.onlineCount} kişi',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.muted.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Fal & Tarot
// ---------------------------------------------------------------------------
class HomeFortuneTarot extends StatelessWidget {
  const HomeFortuneTarot({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Fal & Tarot',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Text(
                'Tüm Falcılar',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.muted.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 145,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              children: const [
                _FortuneCard(
                  icon: '🔮',
                  title: 'Günlük Tarot',
                  subtitle: 'Bugünkü enerjini keşfet',
                  gradient: [Color(0xFF2D1B4E), Color(0xFF1A0A2E)],
                ),
                SizedBox(width: 12),
                _FortuneCard(
                  icon: '❤️',
                  title: 'Aşk Falı',
                  subtitle: 'Kalbinin\nsöylediklerini dinle',
                  gradient: [Color(0xFF4E1B2D), Color(0xFF2E0A1A)],
                ),
                SizedBox(width: 12),
                _FortuneCard(
                  icon: '☕',
                  title: 'Kahve Falı',
                  subtitle: 'Fincandaki\ngizemi çöz',
                  gradient: [Color(0xFF4E3B1B), Color(0xFF2E1A0A)],
                ),
                SizedBox(width: 12),
                _FortuneCard(
                  icon: '💼',
                  title: 'Kariyer Falı',
                  subtitle: 'Yolunu, hedefini\nışığını bul',
                  gradient: [Color(0xFF1B4E3B), Color(0xFF0A2E1A)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FortuneCard extends StatelessWidget {
  const _FortuneCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });

  final String icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 115,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}
