import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/chat_room_dj_state.dart';
import '../../../domain/entities/music_queue_item.dart';
import '../../../presentation/providers/chat_room_providers.dart';
import '../../../presentation/theme/voice_room_tokens.dart';
import '../../../presentation/widgets/premium/voice_glass.dart';

/// Tam müzik kuyruğu — DJ: sıra gör, sil, sırala, geç, tekrar çal.
Future<void> showRoomMusicQueueSheet(
  BuildContext context,
  WidgetRef ref, {
  required String liveKey,
  required ChatRoomDjState dj,
  required bool canControlMusic,
  bool canStopMusic = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12121A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => ProviderScope(
      parent: ProviderScope.containerOf(ctx),
      child: _RoomMusicQueueSheet(
        liveKey: liveKey,
        dj: dj,
        canControlMusic: canControlMusic,
        canStopMusic: canStopMusic,
      ),
    ),
  );
}

class _RoomMusicQueueSheet extends ConsumerStatefulWidget {
  const _RoomMusicQueueSheet({
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
  ConsumerState<_RoomMusicQueueSheet> createState() =>
      _RoomMusicQueueSheetState();
}

class _RoomMusicQueueSheetState extends ConsumerState<_RoomMusicQueueSheet> {
  late List<MusicQueueItem> _queue;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _queue = List<MusicQueueItem>.from(widget.dj.musicQueue);
  }

  @override
  void didUpdateWidget(covariant _RoomMusicQueueSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dj.musicQueue.length != widget.dj.musicQueue.length ||
        oldWidget.dj.nowPlaying?.id != widget.dj.nowPlaying?.id) {
      _queue = List<MusicQueueItem>.from(widget.dj.musicQueue);
    }
  }

  Future<void> _run(Future<String?> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    final err = await action();
    if (mounted) setState(() => _busy = false);
    if (!mounted || err == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  }

  ChatRoomDjState get _liveDj =>
      ref.read(voiceRoomLiveProvider(widget.liveKey)).dj;

  String? get _nowPlayingId => _liveDj.nowPlaying?.id ?? widget.dj.nowPlaying?.id;

  Future<void> _persistOrder() async {
    final ids = _queue.map((e) => e.id).toList();
    await _run(
      () => ref
          .read(voiceRoomLiveProvider(widget.liveKey).notifier)
          .reorderMusicQueue(ids),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final ctrl = ref.read(voiceRoomLiveProvider(widget.liveKey).notifier);
    final nowId = _nowPlayingId;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Müzik kuyruğu (${_queue.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (widget.canControlMusic)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ActionChip(
                      icon: Icons.skip_next_rounded,
                      label: 'Geç',
                      onTap: _busy ? null : () => _run(ctrl.skipMusic),
                    ),
                    _ActionChip(
                      icon: Icons.replay_rounded,
                      label: 'Tekrar',
                      onTap: _busy ? null : () => _run(ctrl.replayMusic),
                    ),
                    if (widget.canStopMusic)
                      _ActionChip(
                        icon: Icons.stop_rounded,
                        label: 'Durdur',
                        color: Colors.redAccent,
                        onTap: _busy ? null : () => _run(ctrl.stopMusic),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _queue.isEmpty
                  ? const Center(
                      child: Text(
                        'Kuyruk boş',
                        style: TextStyle(color: Colors.white60),
                      ),
                    )
                  : widget.canControlMusic
                      ? ReorderableListView.builder(
                          scrollController: scrollController,
                          padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
                          itemCount: _queue.length,
                          onReorder: (oldIndex, newIndex) async {
                            if (newIndex > oldIndex) newIndex--;
                            setState(() {
                              final item = _queue.removeAt(oldIndex);
                              _queue.insert(newIndex, item);
                            });
                            await _persistOrder();
                          },
                          itemBuilder: (context, i) {
                            final item = _queue[i];
                            return _QueueTile(
                              key: ValueKey(item.id),
                              index: i + 1,
                              item: item,
                              isNowPlaying: item.id == nowId,
                              canRemove: widget.canControlMusic &&
                                  item.id != nowId,
                              showDragHandle: widget.canControlMusic,
                              onRemove: () async {
                                await _run(
                                  () => ctrl.removeQueueItem(item.id),
                                );
                              },
                            );
                          },
                        )
                      : ListView.separated(
                          controller: scrollController,
                          padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
                          itemCount: _queue.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final item = _queue[i];
                            return _QueueTile(
                              key: ValueKey(item.id),
                              index: i + 1,
                              item: item,
                              isNowPlaying: item.id == nowId,
                              canRemove: false,
                              showDragHandle: false,
                              onRemove: () {},
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? VoiceRoomTokens.neonPurple;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: c),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: c.withValues(alpha: 0.18),
      side: BorderSide(color: c.withValues(alpha: 0.35)),
      onPressed: onTap,
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({
    super.key,
    required this.index,
    required this.item,
    required this.isNowPlaying,
    required this.canRemove,
    required this.showDragHandle,
    required this.onRemove,
  });

  final int index;
  final MusicQueueItem item;
  final bool isNowPlaying;
  final bool canRemove;
  final bool showDragHandle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final requester = item.requestedBy?.displayName ?? '—';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: VoiceGlass(
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            if (showDragHandle)
              ReorderableDragStartListener(
                index: index - 1,
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: Colors.white.withValues(alpha: 0.45),
                  size: 20,
                ),
              ),
            if (showDragHandle) const SizedBox(width: 6),
            Text(
              '$index',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: isNowPlaying ? VoiceRoomTokens.gold : Colors.white54,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${item.uploader ?? item.artistLine.split(' • ').firstOrNull ?? '—'} • $requester'
                    '${item.duration?.isNotEmpty == true ? ' • ${item.duration}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isNowPlaying)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.equalizer_rounded,
                  color: VoiceRoomTokens.gold,
                  size: 20,
                ),
              ),
            if (canRemove)
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                tooltip: 'Kuyruktan sil',
              ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
