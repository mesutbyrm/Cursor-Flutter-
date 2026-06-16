import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/music_queue_item.dart';
import '../providers/room_music_providers.dart';

/// `!istek` sonrası YouTube Data API arama sonuçları — ilk 5.
Future<YoutubeSearchHit?> showMusicSearchPickerSheet(
  BuildContext context,
  WidgetRef ref, {
  required String query,
}) async {
  return showModalBottomSheet<YoutubeSearchHit>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12121A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _MusicSearchPicker(query: query),
  );
}

class _MusicSearchPicker extends ConsumerStatefulWidget {
  const _MusicSearchPicker({required this.query});

  final String query;

  @override
  ConsumerState<_MusicSearchPicker> createState() => _MusicSearchPickerState();
}

class _MusicSearchPickerState extends ConsumerState<_MusicSearchPicker> {
  late Future<List<YoutubeSearchHit>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(searchMusicUseCaseProvider)(widget.query);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Şarkı seç',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '«${widget.query}»',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<YoutubeSearchHit>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Arama başarısız: ${snap.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  }
                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Text(
                        'Sonuç bulunamadı',
                        style: TextStyle(color: Colors.white60),
                      ),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final hit = items[i];
                      return _SearchResultTile(
                        hit: hit,
                        onTap: () => Navigator.pop(context, hit),
                      );
                    },
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

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.hit, required this.onTap});

  final YoutubeSearchHit hit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E2A),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: hit.thumbUrl != null && hit.thumbUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: hit.thumbUrl!,
                          fit: BoxFit.cover,
                        )
                      : const ColoredBox(
                          color: Color(0xFF2A2A3A),
                          child: Icon(Icons.music_note, color: Colors.white38),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hit.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hit.uploader != null && hit.uploader!.isNotEmpty)
                      Text(
                        hit.uploader!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    if (hit.duration != null && hit.duration!.isNotEmpty)
                      Text(
                        hit.duration!,
                        style: const TextStyle(color: Color(0xFF8B5CF6), fontSize: 12),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF8B5CF6), size: 36),
            ],
          ),
        ),
      ),
    );
  }
}
