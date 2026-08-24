import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';
import 'package:canlifal_social/core/network/api_exception.dart';

import '../../../domain/entities/music_queue_item.dart';
import '../providers/room_music_providers.dart';

/// Web parity — anlık YouTube arama; seçimden sonra sheet kapanır ve çalma başlar.
Future<void> showMusicSearchPickerSheet(
  BuildContext context,
  WidgetRef ref, {
  required String query,
  bool stayOpenOnSelect = false,
  void Function(YoutubeSearchHit hit)? onSelected,
}) async {
  final container = ProviderScope.containerOf(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: const Color(0xFF12121A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => UncontrolledProviderScope(
      container: container,
      child: _MusicSearchPicker(
        initialQuery: query,
        stayOpenOnSelect: stayOpenOnSelect,
        onSelected: onSelected,
      ),
    ),
  );
}

class _MusicSearchPicker extends ConsumerStatefulWidget {
  const _MusicSearchPicker({
    required this.initialQuery,
    this.stayOpenOnSelect = false,
    this.onSelected,
  });

  final String initialQuery;
  final bool stayOpenOnSelect;
  final void Function(YoutubeSearchHit hit)? onSelected;

  @override
  ConsumerState<_MusicSearchPicker> createState() => _MusicSearchPickerState();
}

class _MusicSearchPickerState extends ConsumerState<_MusicSearchPicker> {
  late final TextEditingController _queryCtrl;
  Timer? _debounce;
  var _searchGen = 0;
  var _searching = false;
  var _submitting = false;
  List<YoutubeSearchHit> _hits = const [];
  String? _error;
  String? _selectedId;
  String? _selectedTitle;

  @override
  void initState() {
    super.initState();
    _queryCtrl = TextEditingController(text: widget.initialQuery);
    _queryCtrl.addListener(() => _onQueryChanged(_queryCtrl.text));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final q = widget.initialQuery.trim();
      if (q.isNotEmpty) {
        _search(q);
      }
    });
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
    if (trimmed.isEmpty) {
      setState(() {
        _hits = const [];
        _searching = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 280), () => _search(trimmed));
  }

  Future<void> _search(String q) async {
    final gen = ++_searchGen;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final hits = await ref.read(searchMusicUseCaseProvider)(q);
      if (!mounted || gen != _searchGen) return;
      setState(() {
        _hits = hits;
        _searching = false;
      });
    } catch (e) {
      if (!mounted || gen != _searchGen) return;
      setState(() {
        _searching = false;
        _error = ApiException.userMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
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
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Text('🎵', style: TextStyle(fontSize: 22)),
                      SizedBox(width: 8),
                      Text(
                        'Müzik',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Text(
                      'maksimum 6 dakika',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8B5CF6),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryCtrl,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Şarkı veya sanatçı ara…',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8B5CF6)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
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
            if (_searching || _submitting)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF8B5CF6),
                backgroundColor: Colors.white12,
              ),
            if (_selectedTitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                child: Text(
                  'Çalıyor: $_selectedTitle',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            Expanded(child: _buildBody(scrollController, bottom)),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 12),
              child: Text(
                'YouTube üzerinden çalınmaktadır.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController, double bottom) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Arama başarısız: $_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    if (_queryCtrl.text.trim().isEmpty) {
      return const Center(
        child: Text(
          'Harf veya şarkı adı yazın',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }
    if (!_searching && _hits.isEmpty) {
      return const Center(
        child: Text('Sonuç bulunamadı', style: TextStyle(color: Colors.white60)),
      );
    }
    return ListView.separated(
      controller: scrollController,
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 16),
      itemCount: _hits.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final hit = _hits[i];
        return _SearchResultTile(
          hit: hit,
          compact: i < 3,
          selected: _selectedId == hit.videoId,
          onTap: _submitting
              ? () {}
              : () {
                  if (_submitting) return;
                  setState(() {
                    _selectedId = hit.videoId;
                    _selectedTitle = hit.title;
                    _submitting = true;
                  });
                  final onSelected = widget.onSelected;
                  if (!widget.stayOpenOnSelect && context.mounted) {
                    Navigator.pop(context);
                  }
                  if (onSelected != null) {
                    final selected = hit;
                    // Arama sheet kapanış animasyonu bitsin, sonra mod seçici açılsın (ANR önleme).
                    unawaited(
                      Future<void>.delayed(
                        const Duration(milliseconds: 150),
                        () => onSelected(selected),
                      ),
                    );
                  }
                  if (widget.stayOpenOnSelect && mounted) {
                    setState(() => _submitting = false);
                  }
                },
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.hit,
    required this.onTap,
    this.compact = false,
    this.selected = false,
  });

  final YoutubeSearchHit hit;
  final VoidCallback onTap;
  final bool compact;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final thumb = compact ? 56.0 : 72.0;
    return Material(
      color: selected
          ? const Color(0xFF8B5CF6).withValues(alpha: 0.22)
          : const Color(0xFF1E1E2A),
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
                  width: thumb,
                  height: thumb,
                  child: hit.thumbUrl != null && hit.thumbUrl!.isNotEmpty
                      ? CanlifalNetworkImage(url: hit.thumbUrl!, fit: BoxFit.cover)
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
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: compact ? FontWeight.w700 : FontWeight.w600,
                        fontSize: compact ? 13 : 14,
                      ),
                    ),
                    if (hit.uploader != null && hit.uploader!.isNotEmpty)
                      Text(
                        hit.uploader!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    if (hit.duration != null && hit.duration!.isNotEmpty)
                      Text(
                        hit.duration!,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.45),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF8B5CF6), size: 32),
            ],
          ),
        ),
      ),
    );
  }
}
