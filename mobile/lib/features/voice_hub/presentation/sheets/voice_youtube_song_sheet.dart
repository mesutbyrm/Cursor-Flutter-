import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/music_queue_item.dart';
import '../providers/chat_room_providers.dart';
import '../theme/voice_room_tokens.dart';
import '../widgets/premium/voice_glass.dart';

Future<void> showVoiceYoutubeSongSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _YoutubeSongSheet(room: room),
  );
}

class _YoutubeSongSheet extends ConsumerStatefulWidget {
  const _YoutubeSongSheet({required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<_YoutubeSongSheet> createState() => _YoutubeSongSheetState();
}

class _YoutubeSongSheetState extends ConsumerState<_YoutubeSongSheet> {
  final _queryCtrl = TextEditingController();
  Timer? _debounce;
  var _searching = false;
  var _submitting = false;
  List<YoutubeSearchHit> _hits = const [];
  String? _error;
  int _cost = 10;

  @override
  void initState() {
    super.initState();
    _loadQueueMeta();
  }

  Future<void> _loadQueueMeta() async {
    try {
      final data = await ref
          .read(voiceRoomLiveProvider(widget.room).notifier)
          .fetchMusicQueue();
      if (mounted) setState(() => _cost = data.cost);
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() {
        _hits = const [];
        _searching = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(trimmed));
  }

  Future<void> _search(String q) async {
    final query = q.trim();
    if (query.length < 2) {
      if (mounted) setState(() => _hits = const []);
      return;
    }
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final hits = await ref
          .read(voiceRoomLiveProvider(widget.room).notifier)
          .searchYoutube(query);
      if (mounted) {
        setState(() {
          _hits = hits;
          _searching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _searching = false;
          _error = ApiException.userMessage(e);
        });
      }
    } finally {
      if (mounted && _searching) {
        setState(() => _searching = false);
      }
    }
  }

  Future<void> _request(YoutubeSearchHit hit) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    String? err;
    try {
      err = await ref.read(voiceRoomLiveProvider(widget.room).notifier).requestMusic(
            title: hit.title,
            youtubeUrl: hit.url,
            thumbUrl: hit.thumbUrl,
            videoId: hit.videoId,
          );
    } catch (e) {
      err = ApiException.userMessage(e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
    if (!mounted) return;
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    ref.invalidate(coinBalanceProvider);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Şarkı sıraya eklendi · $_cost jeton')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final coins = ref.watch(coinBalanceProvider).valueOrNull;
    final live = ref.watch(voiceRoomLiveProvider(widget.room));
    final queue = live.dj.musicQueue;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scroll) => VoiceGlass(
          borderRadius: 24,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              const SizedBox(height: 12),
              const Text(
                'Şarkı İsteği',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                'YouTube\'da ara · her istek $_cost jeton${coins != null ? ' · bakiye: $coins' : ''}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _queryCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Şarkı veya sanatçı ara...',
                  hintStyle: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.8)),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.accentPink),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: _onQueryChanged,
                onSubmitted: _search,
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.liveRed, fontSize: 11)),
              ],
              const SizedBox(height: 10),
              if (_searching)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    controller: scroll,
                    children: [
                      if (queue.isNotEmpty) ...[
                        Text(
                          'Sıradaki (${queue.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: VoiceRoomTokens.gold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ...queue.map((q) => _QueueTile(item: q)),
                        const SizedBox(height: 12),
                      ],
                      if (_hits.isEmpty && _queryCtrl.text.trim().length >= 2)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'Sonuç bulunamadı',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                      ..._hits.map(
                        (h) => _HitTile(
                          hit: h,
                          cost: _cost,
                          submitting: _submitting,
                          onTap: () => _request(h),
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

class _HitTile extends StatelessWidget {
  const _HitTile({
    required this.hit,
    required this.cost,
    required this.submitting,
    required this.onTap,
  });

  final YoutubeSearchHit hit;
  final int cost;
  final bool submitting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: hit.thumbUrl != null && hit.thumbUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: hit.thumbUrl!,
                width: 56,
                height: 42,
                fit: BoxFit.cover,
              )
            : Container(
                width: 56,
                height: 42,
                color: Colors.white12,
                child: const Icon(Icons.music_video_rounded, color: Colors.white54),
              ),
      ),
      title: Text(
        hit.title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
      subtitle: hit.uploader != null
          ? Text(
              hit.uploader!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            )
          : null,
      trailing: FilledButton(
        onPressed: submitting ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: VoiceRoomTokens.neonPurple,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          minimumSize: const Size(0, 32),
        ),
        child: Text('$cost J', style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}

class _QueueTile extends StatelessWidget {
  const _QueueTile({required this.item});

  final MusicQueueItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.queue_music_rounded, color: AppColors.accentPink, size: 20),
      title: Text(
        item.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12),
      ),
      subtitle: item.requestedBy != null
          ? Text(
              item.requestedBy!.displayWithPrefix,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            )
          : null,
    );
  }
}
