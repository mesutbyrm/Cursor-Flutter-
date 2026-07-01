import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/short_video_upload_service.dart';
import '../../domain/entities/short_explore_entity.dart';
import '../../domain/entities/short_upload_draft.dart';
import '../../domain/entities/short_video_entity.dart';
import '../../domain/repositories/shorts_repository.dart';
import '../providers/shorts_providers.dart';
import '../utils/shorts_api_message.dart';
import 'short_studio_providers.dart';
import 'studio_voiceover_sheet.dart';

/// Açıklama, mention, hashtag, müzik, gizlilik ve yükleme ilerlemesi.
class StudioPublishPage extends ConsumerStatefulWidget {
  const StudioPublishPage({
    super.key,
    required this.onBack,
    required this.onPublished,
  });

  final VoidCallback onBack;
  final VoidCallback onPublished;

  @override
  ConsumerState<StudioPublishPage> createState() => _StudioPublishPageState();
}

class _StudioPublishPageState extends ConsumerState<StudioPublishPage> {
  final _descCtrl = TextEditingController();
  CancelToken? _cancelToken;
  var _uploading = false;
  var _progress = 0.0;
  String? _error;
  List<ShortVideoAuthor> _mentionHits = const [];
  List<ShortHashtagEntity> _hashtagHits = const [];
  List<ShortMusicEntity> _musicHits = const [];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(shortUploadDraftProvider);
    _descCtrl.text = draft.description;
    _descCtrl.addListener(_onDescChanged);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _cancelToken?.cancel('dispose');
    super.dispose();
  }

  void _onDescChanged() {
    final text = _descCtrl.text;
    ref.read(shortUploadDraftProvider.notifier).patch(
          (d) => d.copyWith(description: text),
        );
    final at = _activeToken(text, '@');
    final hash = _activeToken(text, '#');
    if (at != null && at.length >= 2) {
      ref.read(shortsRepositoryProvider).searchMentions(at).then((users) {
        if (mounted) setState(() => _mentionHits = users);
      });
    } else {
      setState(() => _mentionHits = const []);
    }
    if (hash != null && hash.length >= 1) {
      ref.read(shortsRepositoryProvider).searchHashtags(hash).then((tags) {
        if (mounted) setState(() => _hashtagHits = tags);
      });
    } else {
      setState(() => _hashtagHits = const []);
    }
  }

  String? _activeToken(String text, String trigger) {
    final i = text.lastIndexOf(trigger);
    if (i < 0) return null;
    final tail = text.substring(i + 1);
    if (tail.contains(' ') || tail.contains('\n')) return null;
    return tail;
  }

  void _insertMention(ShortVideoAuthor user) {
    final text = _descCtrl.text;
    final i = text.lastIndexOf('@');
    if (i < 0) return;
    final next = '${text.substring(0, i)}@${user.username} ';
    _descCtrl.text = next;
    _descCtrl.selection = TextSelection.collapsed(offset: next.length);
    ref.read(shortUploadDraftProvider.notifier).patch((d) {
      if (d.mentionUserIds.contains(user.id)) return d;
      return d.copyWith(mentionUserIds: [...d.mentionUserIds, user.id]);
    });
    setState(() => _mentionHits = const []);
  }

  void _insertHashtag(String name) {
    final text = _descCtrl.text;
    final i = text.lastIndexOf('#');
    if (i < 0) return;
    final tag = name.replaceAll('#', '');
    final next = '${text.substring(0, i)}#$tag ';
    _descCtrl.text = next;
    _descCtrl.selection = TextSelection.collapsed(offset: next.length);
    setState(() => _hashtagHits = const []);
  }

  Future<void> _searchMusic(String q) async {
    final list = await ref.read(shortsRepositoryProvider).searchMusic(q);
    if (mounted) setState(() => _musicHits = list);
  }

  Future<void> _publish() async {
    if (_uploading) return;
    final draft = ref.read(shortUploadDraftProvider).copyWith(
          description: _descCtrl.text.trim(),
        );
    if (draft.videoPath == null) {
      setState(() => _error = 'Video dosyası yok.');
      return;
    }
    setState(() {
      _uploading = true;
      _error = null;
      _progress = 0;
    });
    _cancelToken = CancelToken();
    try {
      await ref.read(shortVideoUploadServiceProvider).publish(
            draft: draft,
            cancelToken: _cancelToken,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      ref.invalidate(shortsFeedProvider);
      ref.invalidate(shortsExploreProvider);
      ref.read(shortsFeedProvider(ShortsFeedTab.forYou).notifier).refresh();
      if (!mounted) return;
      widget.onPublished();
    } catch (e) {
      if (mounted) {
        setState(() => _error = shortsErrorMessage(e));
        showShortsSnackBar(context, shortsErrorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickVisibility(ShortVisibility current) async {
    final picked = await showModalBottomSheet<ShortVisibility>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in ShortVisibility.values)
              ListTile(title: Text(v.label), onTap: () => Navigator.pop(ctx, v)),
          ],
        ),
      ),
    );
    if (picked != null) {
      ref.read(shortUploadDraftProvider.notifier).patch(
            (d) => d.copyWith(visibility: picked),
          );
    }
  }

  Future<void> _pickCommentSetting(ShortCommentSetting current) async {
    final picked = await showModalBottomSheet<ShortCommentSetting>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in ShortCommentSetting.values)
              ListTile(title: Text(v.label), onTap: () => Navigator.pop(ctx, v)),
          ],
        ),
      ),
    );
    if (picked != null) {
      ref.read(shortUploadDraftProvider.notifier).patch(
            (d) => d.copyWith(commentSetting: picked),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(shortUploadDraftProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _uploading ? null : widget.onBack,
        ),
        title: const Text('Yayınla'),
        actions: [
          TextButton(
            onPressed: _uploading ? null : _publish,
            child: const Text('Paylaş', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_uploading) ...[
            LinearProgressIndicator(value: _progress > 0 ? _progress : null),
            const SizedBox(height: 8),
            Text(
              'Yükleniyor ${(_progress * 100).round()}%',
              style: const TextStyle(color: Colors.white70),
            ),
            TextButton(
              onPressed: () {
                _cancelToken?.cancel('user');
                setState(() => _uploading = false);
              },
              child: const Text('İptal'),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _descCtrl,
            maxLength: 2200,
            maxLines: 6,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Açıklama',
              hintText: '@mention #hashtag',
              counterStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_mentionHits.isNotEmpty)
            _SuggestionList(
              items: _mentionHits.map((u) => '@${u.username}').toList(),
              onTap: (i) => _insertMention(_mentionHits[i]),
            ),
          if (_hashtagHits.isNotEmpty)
            _SuggestionList(
              items: _hashtagHits.map((h) => '#${h.name}').toList(),
              onTap: (i) => _insertHashtag(_hashtagHits[i].name),
            ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: Text(draft.musicTitle ?? 'Müzik ekle'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await _searchMusic('');
              if (!context.mounted) return;
              final picked = await showModalBottomSheet<ShortMusicEntity>(
                context: context,
                backgroundColor: const Color(0xFF121218),
                isScrollControlled: true,
                builder: (ctx) => _MusicPickerSheet(
                  items: _musicHits,
                  onSearch: (q) async {
                    final list =
                        await ref.read(shortsRepositoryProvider).searchMusic(q);
                    if (mounted) setState(() => _musicHits = list);
                    return list;
                  },
                ),
              );
              if (picked != null) {
                ref.read(shortUploadDraftProvider.notifier).patch(
                      (d) => d.copyWith(
                        musicId: picked.id,
                        musicTitle: picked.title,
                      ),
                    );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.mic_none_rounded),
            title: const Text('Seslendirme kaydet'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showStudioVoiceoverSheet(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: Text(draft.locationLabel ?? 'Konum ekle'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final label = await showDialog<String>(
                context: context,
                builder: (ctx) {
                  final c = TextEditingController(text: draft.locationLabel);
                  return AlertDialog(
                    title: const Text('Konum'),
                    content: TextField(
                      controller: c,
                      decoration: const InputDecoration(hintText: 'Şehir veya mekan'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, c.text.trim()),
                        child: const Text('Kaydet'),
                      ),
                    ],
                  );
                },
              );
              if (label != null && label.isNotEmpty) {
                ref.read(shortUploadDraftProvider.notifier).patch(
                      (d) => d.copyWith(locationLabel: label),
                    );
              }
            },
          ),
          const Divider(height: 24),
          ListTile(
            title: const Text('Kimler görebilir'),
            subtitle: Text(draft.visibility.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickVisibility(draft.visibility),
          ),
          ListTile(
            title: const Text('Yorum ayarları'),
            subtitle: Text(draft.commentSetting.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickCommentSetting(draft.commentSetting),
          ),
          SwitchListTile(
            title: const Text('Düet / remix izni'),
            value: draft.allowDuet,
            onChanged: (v) => ref
                .read(shortUploadDraftProvider.notifier)
                .patch((d) => d.copyWith(allowDuet: v)),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            FilledButton(onPressed: _publish, child: const Text('Tekrar dene')),
          ],
        ],
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.items, required this.onTap});

  final List<String> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white10,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            ListTile(
              dense: true,
              title: Text(items[i]),
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _MusicPickerSheet extends StatefulWidget {
  const _MusicPickerSheet({
    required this.items,
    required this.onSearch,
  });

  final List<ShortMusicEntity> items;
  final Future<List<ShortMusicEntity>> Function(String q) onSearch;

  @override
  State<_MusicPickerSheet> createState() => _MusicPickerSheetState();
}

class _MusicPickerSheetState extends State<_MusicPickerSheet> {
  final _q = TextEditingController();
  late List<ShortMusicEntity> _items;

  @override
  void initState() {
    super.initState();
    _items = widget.items;
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _q,
            decoration: InputDecoration(
              hintText: 'Şarkı ara',
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
            onPressed: () async {
              final list = await widget.onSearch(_q.text);
              if (mounted) setState(() => _items = list);
            },
          ),
        ),
        onSubmitted: (v) async {
          final list = await widget.onSearch(v);
          if (mounted) setState(() => _items = list);
        },
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final m = _items[i];
                return ListTile(
                  title: Text(m.title),
                  subtitle: m.artist != null ? Text(m.artist!) : null,
                  onTap: () => Navigator.pop(context, m),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
