import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glow_panel.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';

/// Ana sayfa hızlı işlemler (davet, jeton).
class FeedQuickActions extends StatelessWidget {
  const FeedQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlowPanel(
        borderRadius: 18,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitleRow(
              icon: Icons.bolt_rounded,
              title: 'Hızlı işlemler',
              accent: AppTheme.accentSecondary,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickTile(
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Arkadaşlarını\ndavet et',
                    gradient: [
                      AppTheme.accent.withValues(alpha: 0.45),
                      AppTheme.accentSecondary.withValues(alpha: 0.3),
                    ],
                    onTap: () => context.push('/invite-friends'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickTile(
                    icon: Icons.monetization_on_rounded,
                    label: 'Jeton\nyükle',
                    gradient: [
                      const Color(0xFF5C4020).withValues(alpha: 0.85),
                      const Color(0xFF2A1C10).withValues(alpha: 0.9),
                    ],
                    onTap: () => context.push('/jeton-store'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Colors.white.withValues(alpha: 0.95)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ana sayfa (Akış) üstünde canlifal.com canlı yayın şeridi.
class FeedLiveStrip extends ConsumerWidget {
  const FeedLiveStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveStreamsProvider);
    return live.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (streams) {
        final onAir = streams.where((s) => s.isLive).toList();
        if (onAir.isEmpty) return const SizedBox.shrink();
        return GlowPanel(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionTitleRow(
                icon: Icons.live_tv_rounded,
                title: 'Canlı yayınlar',
                accent: AppTheme.accentSecondary,
                trailing: TextButton(
                  onPressed: () => context.go('/live'),
                  child: const Text('Tümü'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 138,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: onAir.length > 12 ? 12 : onAir.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) {
                    final s = onAir[i];
                    return _LiveChip(stream: s);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LiveChip extends StatelessWidget {
  const _LiveChip({required this.stream});

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
    return Material(
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: stream.isLive ? () => _open(context) : null,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 118,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      stream.thumbnailUrl != null &&
                              stream.thumbnailUrl!.isNotEmpty
                          ? Image.network(
                              stream.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const ColoredBox(
                                color: AppTheme.surface,
                                child: Icon(Icons.live_tv_rounded,
                                    color: AppTheme.accent, size: 36),
                              ),
                            )
                          : const ColoredBox(
                              color: AppTheme.surface,
                              child: Icon(Icons.live_tv_rounded,
                                  color: AppTheme.accent, size: 36),
                            ),
                      if (stream.isLive)
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accent.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: const Text(
                              'CANLI',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.streamerName ?? 'Yayıncı',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${stream.viewerCount} izleyici',
                      style: TextStyle(
                        color: AppTheme.muted.withValues(alpha: 0.95),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Site ile aynı sesli sohbet odaları (`/api/chat/rooms`).
class FeedVoiceRoomsStrip extends ConsumerWidget {
  const FeedVoiceRoomsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!Env.useNextAuth) return const SizedBox.shrink();
    final rooms = ref.watch(voiceRoomsProvider);
    return rooms.when(
      loading: () => const SizedBox(
        height: 72,
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: GlowPanel(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitleRow(
                  icon: Icons.graphic_eq_rounded,
                  title: 'Sesli sohbet odaları',
                  accent: AppTheme.accent,
                  trailing: TextButton(
                    onPressed: () => context.push('/voice-rooms'),
                    child: const Text('Tümü'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (ctx, i) => _RoomChip(room: list[i]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoomChip extends StatelessWidget {
  const _RoomChip({required this.room});

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
    return Material(
      color: const Color(0xFF1E1E2A),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 124,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.22),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.accent.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(room.icon ?? '💬', style: const TextStyle(fontSize: 20)),
                  const Spacer(),
                  if (room.onlineCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${room.onlineCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                room.nameTr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if (room.ownerName != null) ...[
                const Spacer(),
                Text(
                  room.ownerName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.muted, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
