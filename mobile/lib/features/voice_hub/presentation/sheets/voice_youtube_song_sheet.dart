import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/music_queue_item.dart';
import '../providers/chat_room_providers.dart';
import '../theme/voice_room_tokens.dart';

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
  final _giftCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  Timer? _debounce;
  var _searching = false;
  var _submitting = false;
  List<YoutubeSearchHit> _hits = const [];
  YoutubeSearchHit? _selected;
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
    _giftCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      setState(() {
        _hits = const [];
        _selected = null;
        _searching = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(trimmed));
  }

  Future<void> _search(String q) async {
    if (q.trim().length < 2) return;
    setState(() {
      _searching = true;
      _error = null;
      _selected = null;
    });
    try {
      final hits = await ref
          .read(voiceRoomLiveProvider(widget.room).notifier)
          .searchYoutube(q.trim());
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
    }
  }

  Future<void> _submit() async {
    final hit = _selected;
    if (hit == null || _submitting) return;
    setState(() => _submitting = true);
    String? err;
    try {
      err = await ref.read(voiceRoomLiveProvider(widget.room).notifier).requestMusic(
            title: hit.title,
            youtubeUrl: hit.url,
            thumbUrl: hit.thumbUrl,
            videoId: hit.videoId,
            giftTo: _giftCtrl.text.trim().isEmpty ? null : _giftCtrl.text.trim(),
            note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
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
    final coins = ref.watch(coinBalanceProvider).valueOrNull ?? 0;
    final balanceLabel = NumberFormat.decimalPattern('tr').format(coins);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF12082A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: const Color(0xFF7B2FF7).withValues(alpha: 0.55),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.music_note_rounded, color: AppThemeColors.accentPink),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Şarkı İsteği',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: Colors.white,
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.35,
                  ),
                  children: [
                    const TextSpan(
                      text:
                          "YouTube'dan şarkı arayın ve isteğinizi gönderin. Her istek ",
                    ),
                    TextSpan(
                      text: '$_cost 💎 Jeton',
                      style: const TextStyle(
                        color: VoiceRoomTokens.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(text: ' harcar.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _queryCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Şarkı adı veya sanatçı ara...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: const Color(0xFF7B2FF7).withValues(alpha: 0.4),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: const Color(0xFF7B2FF7).withValues(alpha: 0.35),
                    ),
                  ),
                ),
                onChanged: _onQueryChanged,
                onSubmitted: _search,
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppThemeColors.liveRed, fontSize: 11),
                ),
              ),
            if (_searching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                shrinkWrap: true,
                children: [
                  ..._hits.map((h) {
                    final sel = _selected?.videoId == h.videoId;
                    return _SearchResultTile(
                      hit: h,
                      selected: sel,
                      onTap: () => setState(() => _selected = h),
                    );
                  }),
                  if (_selected != null) ...[
                    const SizedBox(height: 12),
                    _SelectedSongField(title: _selected!.title),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _giftCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Kime armağan? (opsiyonel)',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteCtrl,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Kısa not (opsiyonel)',
                        hintStyle: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: FilledButton.icon(
                onPressed: _selected == null || _submitting ? null : _submit,
                icon: const Icon(Icons.music_note_rounded),
                label: Text('İstek Gönder ($_cost 💎)'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF7B2FF7),
                  disabledBackgroundColor: const Color(0xFF7B2FF7).withValues(alpha: 0.35),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Bakiye: $balanceLabel Jeton',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({
    required this.hit,
    required this.selected,
    required this.onTap,
  });

  final YoutubeSearchHit hit;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? const Color(0xFF7B2FF7).withValues(alpha: 0.25)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? const Color(0xFF7B2FF7)
                    : Colors.white.withValues(alpha: 0.08),
                width: selected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: hit.thumbUrl != null && hit.thumbUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: hit.thumbUrl!,
                          width: 72,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 72,
                          height: 48,
                          color: Colors.white12,
                          child: const Icon(Icons.music_video_rounded),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hit.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                      if (hit.subtitleLine.isNotEmpty)
                        Text(
                          hit.subtitleLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF7B2FF7))
                else
                  const SizedBox(width: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedSongField extends StatelessWidget {
  const _SelectedSongField({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: title),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.music_note_rounded, color: AppThemeColors.accentPink),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: const Color(0xFF7B2FF7).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
