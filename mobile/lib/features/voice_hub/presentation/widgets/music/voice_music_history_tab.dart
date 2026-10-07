import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../domain/entities/room_music_history_entry.dart';
import '../../providers/chat_room_providers.dart';

/// Oda müzik geçmişi — `GET /api/music/history?roomId=`.
/// Satıra dokunmak şarkı adını arama sekmesine taşır (tekrar istek).
class VoiceMusicHistoryTab extends ConsumerStatefulWidget {
  const VoiceMusicHistoryTab({
    super.key,
    required this.roomId,
    required this.onRequestAgain,
  });

  final String roomId;
  final ValueChanged<String> onRequestAgain;

  @override
  ConsumerState<VoiceMusicHistoryTab> createState() =>
      _VoiceMusicHistoryTabState();
}

class _VoiceMusicHistoryTabState extends ConsumerState<VoiceMusicHistoryTab> {
  late Future<List<RoomMusicHistoryEntry>> _future = _load();

  Future<List<RoomMusicHistoryEntry>> _load() =>
      ref.read(chatRoomRemoteProvider).fetchMusicHistory(widget.roomId);

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<RoomMusicHistoryEntry>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return _Message(
            text: ApiException.userMessage(snap.error!),
            onRetry: _refresh,
          );
        }
        final items = snap.data ?? const <RoomMusicHistoryEntry>[];
        if (items.isEmpty) {
          return _Message(
            text: 'Bu odada henüz çalınmış şarkı yok.',
            onRetry: _refresh,
          );
        }
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final e = items[i];
              final sub = [
                if ((e.requestedByName ?? '').isNotEmpty) e.requestedByName!,
                if (e.duration.isNotEmpty) e.duration,
                if (e.isPaid) 'Ücretli',
                if (e.playedAt != null) _ago(e.playedAt!),
              ].join(' · ');
              return Material(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: Icon(
                    e.isVideo
                        ? Icons.ondemand_video_rounded
                        : Icons.music_note_rounded,
                    color: Colors.white70,
                  ),
                  title: Text(
                    e.title.isNotEmpty ? e.title : e.videoId,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: sub.isEmpty
                      ? null
                      : Text(
                          sub,
                          style: const TextStyle(color: Colors.white54),
                        ),
                  trailing: const Icon(Icons.replay_rounded, color: Colors.white54),
                  onTap: e.title.isEmpty
                      ? null
                      : () => widget.onRequestAgain(e.title),
                ),
              );
            },
          ),
        );
      },
    );
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t.toLocal());
    if (d.inMinutes < 1) return 'az önce';
    if (d.inHours < 1) return '${d.inMinutes} dk önce';
    if (d.inDays < 1) return '${d.inHours} sa önce';
    return '${d.inDays} gün önce';
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.onRetry});

  final String text;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: const Text('Yenile')),
          ],
        ),
      ),
    );
  }
}
