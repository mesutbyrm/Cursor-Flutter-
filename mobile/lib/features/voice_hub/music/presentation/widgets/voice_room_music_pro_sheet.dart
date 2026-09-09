import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../../presentation/providers/chat_room_providers.dart';
import 'room_music_queue_sheet.dart';

/// Profesyonel müzik bottom sheet — Şimdi Çalıyor / Sıradaki / İstek Gönder.
Future<void> showVoiceRoomMusicProSheet(
  BuildContext context,
  WidgetRef ref, {
  required String liveKey,
  required ChatRoomDjState dj,
  required bool canControlMusic,
  bool canStopMusic = false,
  required VoidCallback onRequestSong,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12121A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => DefaultTabController(
      length: 3,
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                '🎵 Müzik',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const TabBar(
                labelColor: Color(0xFFB832FF),
                unselectedLabelColor: Colors.white54,
                indicatorColor: Color(0xFFB832FF),
                tabs: [
                  Tab(text: 'Şimdi Çalıyor'),
                  Tab(text: 'Sıradaki'),
                  Tab(text: 'İstek Gönder'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _NowPlayingTab(dj: dj, liveKey: liveKey),
                    _QueuePreviewTab(
                      liveKey: liveKey,
                      dj: dj,
                      canControlMusic: canControlMusic,
                      canStopMusic: canStopMusic,
                    ),
                    _RequestTab(onRequestSong: () {
                      Navigator.pop(ctx);
                      onRequestSong();
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

class _NowPlayingTab extends ConsumerWidget {
  const _NowPlayingTab({required this.dj, required this.liveKey});

  final ChatRoomDjState dj;
  final String liveKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveDj = ref.watch(voiceRoomLiveProvider(liveKey)).dj;
    final now = liveDj.nowPlaying ?? dj.nowPlaying;
    if (now == null) {
      return const Center(
        child: Text(
          'Şu an çalan parça yok',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.music_note_rounded, size: 80, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            now.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          if (now.requestedBy != null) ...[
            const SizedBox(height: 6),
            Text(
              'İsteyen: ${now.requestedBy!.name}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
            ),
          ],
          const SizedBox(height: 20),
          const LinearProgressIndicator(
            color: Color(0xFFB832FF),
            backgroundColor: Colors.white12,
          ),
          const SizedBox(height: 8),
          const Text(
            'Sunucu kuyruğu ile senkron',
            style: TextStyle(fontSize: 11, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

class _QueuePreviewTab extends ConsumerWidget {
  const _QueuePreviewTab({
    required this.liveKey,
    required this.dj,
    required this.canControlMusic,
    required this.canStopMusic,
  });

  final String liveKey;
  final ChatRoomDjState dj;
  final bool canControlMusic;
  final bool canStopMusic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveDj = ref.watch(voiceRoomLiveProvider(liveKey)).dj;
    final queue = liveDj.musicQueue.isNotEmpty ? liveDj.musicQueue : dj.musicQueue;
    return Column(
      children: [
        Expanded(
          child: queue.isEmpty
              ? const Center(
                  child: Text(
                    'Kuyruk boş',
                    style: TextStyle(color: Colors.white54),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: queue.length,
                  itemBuilder: (context, i) {
                    final item = queue[i];
                    return _QueueRow(index: i + 1, item: item);
                  },
                ),
        ),
        if (canControlMusic)
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                showRoomMusicQueueSheet(
                  context,
                  ref,
                  liveKey: liveKey,
                  dj: liveDj,
                  canControlMusic: canControlMusic,
                  canStopMusic: canStopMusic,
                );
              },
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Kuyruğu yönet (DJ)'),
            ),
          ),
      ],
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({required this.index, required this.item});

  final int index;
  final MusicQueueItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            '$index.',
            style: const TextStyle(
              color: Color(0xFFB832FF),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.requestedBy != null)
                  Text(
                    item.requestedBy!.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.55),
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

class _RequestTab extends StatelessWidget {
  const _RequestTab({required this.onRequestSong});

  final VoidCallback onRequestSong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Şarkı ara ve kuyruğa istek gönder',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onRequestSong,
            icon: const Icon(Icons.search_rounded),
            label: const Text('Şarkı Ara / İstek Gönder'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB832FF),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }
}
