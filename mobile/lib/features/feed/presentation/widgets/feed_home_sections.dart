import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/env.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../canlifal_web/presentation/canlifal_web_view_page.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';

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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Row(
                children: [
                  Icon(Icons.live_tv_rounded,
                      color: AppTheme.accentSecondary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Canlı yayınlar',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/live'),
                    child: const Text('Tümü'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 132,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                itemCount: onAir.length > 12 ? 12 : onAir.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final s = onAir[i];
                  return _LiveChip(stream: s);
                },
              ),
            ),
          ],
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
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: stream.isLive ? () => _open(context) : null,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 112,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: stream.thumbnailUrl != null &&
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
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.streamerName ?? 'Yayıncı',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '${stream.viewerCount} izleyici',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 10,
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Row(
                children: [
                  const Icon(Icons.headset_mic_rounded,
                      color: AppTheme.accent, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Sohbet odaları',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/voice-rooms'),
                    child: const Text('Tümü'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 104,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) => _RoomChip(room: list[i]),
              ),
            ),
          ],
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
      color: AppTheme.surfaceElevated,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 118,
          padding: const EdgeInsets.all(8),
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
