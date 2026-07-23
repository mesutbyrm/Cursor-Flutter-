import 'dart:async';
import 'dart:io';

import 'package:canlifal_social/core/providers/auth_selectors.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/content/content_guard.dart';
import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../data/services/short_video_upload_service.dart';
import '../../data/shorts_ai_helper.dart';
import '../../domain/entities/short_explore_entity.dart';
import '../../domain/entities/short_upload_draft.dart';
import '../../domain/entities/short_video_entity.dart';
import '../../domain/repositories/shorts_repository.dart';
import '../../domain/utils/short_copyright_guard.dart';
import '../providers/shorts_providers.dart';
import '../utils/shorts_api_message.dart';
import 'short_studio_providers.dart';
import 'studio_cover_picker.dart';
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
  var _savingDraft = false;
  var _progress = 0.0;
  String? _error;
  var _aiLoading = false;
  List<ShortVideoAuthor> _mentionHits = const [];
  List<ShortHashtagEntity> _hashtagHits = const [];
  List<ShortMusicEntity> _musicHits = const [];

  static const _creativeCommonsMusic = <ShortMusicEntity>[
    ShortMusicEntity(
      id: 'cc:ambient-dream',
      title: 'Ambient Dream',
      artist: 'Creative Commons',
    ),
    ShortMusicEntity(
      id: 'cc:cinematic-pulse',
      title: 'Cinematic Pulse',
      artist: 'Creative Commons',
    ),
    ShortMusicEntity(
      id: 'cc:lofi-mystic',
      title: 'Lo-Fi Mystic',
      artist: 'Creative Commons',
    ),
    ShortMusicEntity(
      id: 'cc:soft-piano',
      title: 'Soft Piano Reflection',
      artist: 'Creative Commons',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final draft = ref.read(shortUploadDraftProvider);
    _descCtrl.text = draft.description;
    _descCtrl.addListener(_onDescChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (draft.thumbnailCandidates.isEmpty) {
        unawaited(_aiGenerateThumbnails(silent: true));
      }
    });
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
    final list = await ref
        .read(shortsRepositoryProvider)
        .searchMusic(q)
        .catchError((_) => const <ShortMusicEntity>[]);
    if (mounted) setState(() => _musicHits = _musicWithFallback(list));
  }

  List<ShortMusicEntity> _musicWithFallback(List<ShortMusicEntity> items) {
    if (items.isEmpty) return _creativeCommonsMusic;
    final ids = items.map((e) => e.id).toSet();
    return [
      ...items,
      for (final m in _creativeCommonsMusic)
        if (!ids.contains(m.id)) m,
    ];
  }

  Future<void> _saveDraft() async {
    if (_savingDraft || _uploading) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      showShortsSnackBar(context, 'Taslak kaydetmek için giriş yapın.');
      return;
    }
    setState(() => _savingDraft = true);
    try {
      final draft = ref.read(shortUploadDraftProvider).copyWith(
            description: _descCtrl.text.trim(),
          );
      ref.read(shortUploadDraftProvider.notifier).patch((_) => draft);
      await ref.read(shortUploadDraftProvider.notifier).saveDraft(userId);
      ref.invalidate(shortSavedDraftsProvider(userId));
      if (!mounted) return;
      showShortsSnackBar(context, 'Taslak kaydedildi.');
    } catch (e) {
      if (mounted) showShortsSnackBar(context, 'Taslak kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  Future<void> _runAi(Future<void> Function() action) async {
    if (_aiLoading || _uploading) return;
    setState(() => _aiLoading = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showShortsSnackBar(context, 'AI: $e');
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  Future<void> _aiSuggestAll() async {
    await _runAi(() async {
      final draft = ref.read(shortUploadDraftProvider);
      final desc = _descCtrl.text.trim();
      var meta = await ref.read(shortsRepositoryProvider).suggestMetadata(
            description: desc,
            liveClipId: draft.sourceLiveClipId,
          );
      if (meta.summary == null && meta.hashtags.isEmpty) {
        meta = ShortsAiHelper.fallbackMetadata(desc);
      }
      var descNext = desc;
      if (meta.summary != null && meta.summary!.isNotEmpty && desc.isEmpty) {
        descNext = meta.summary!;
      }
      for (final tag in meta.hashtags.take(5)) {
        if (!descNext.contains('#$tag')) {
          descNext = '$descNext${descNext.isEmpty ? '' : ' '}#$tag';
        }
      }
      _descCtrl.text = descNext.trim();
      ref.read(shortUploadDraftProvider.notifier).patch(
            (d) => d.copyWith(
              description: descNext.trim(),
              aiSummary: meta.summary,
              aiHashtags: meta.hashtags,
              subtitlesSrt: meta.subtitles ?? ShortsAiHelper.fallbackSubtitles(descNext),
            ),
          );
      if (mounted) showShortsSnackBar(context, 'AI önerileri uygulandı.');
    });
  }

  Future<void> _aiRecommendMusic() async {
    await _runAi(() async {
      final draft = ref.read(shortUploadDraftProvider);
      final desc = _descCtrl.text.trim();
      var list = await ref.read(shortsRepositoryProvider).recommendMusic(
            description: desc,
            hashtags: draft.aiHashtags,
          );
      if (list.isEmpty) {
        list = _musicWithFallback(
          await ref
              .read(shortsRepositoryProvider)
              .searchMusic('')
              .catchError((_) => const <ShortMusicEntity>[]),
        );
      }
      if (list.isEmpty) {
        if (mounted) showShortsSnackBar(context, 'Müzik önerisi bulunamadı.');
        return;
      }
      final picked = list.first;
      ref.read(shortUploadDraftProvider.notifier).patch(
            (d) => d.copyWith(musicId: picked.id, musicTitle: picked.title),
          );
      if (mounted) {
        showShortsSnackBar(context, 'Önerilen müzik: ${picked.title}');
      }
    });
  }

  Future<void> _aiGenerateThumbnails({bool silent = false}) async {
    await _runAi(() async {
      final path = ref.read(shortUploadDraftProvider).videoPath;
      if (path == null) {
        if (!silent && mounted) {
          showShortsSnackBar(context, 'Önce video seçin.');
        }
        return;
      }
      final thumbs = await ShortsAiHelper.generateThumbnailCandidates(path);
      if (thumbs.isEmpty) {
        if (!silent && mounted) {
          showShortsSnackBar(context, 'Kapak oluşturulamadı.');
        }
        return;
      }
      ref.read(shortUploadDraftProvider.notifier).patch(
            (d) => d.copyWith(
              thumbnailCandidates: thumbs,
              thumbnailPath: d.thumbnailPath ?? thumbs.first,
            ),
          );
      if (!silent && mounted) {
        showShortsSnackBar(context, '${thumbs.length} kapak önerisi hazır.');
      }
    });
  }

  Future<void> _aiGenerateSubtitles() async {
    await _runAi(() async {
      final desc = _descCtrl.text.trim();
      final srt = ShortsAiHelper.fallbackSubtitles(desc);
      ref.read(shortUploadDraftProvider.notifier).patch(
            (d) => d.copyWith(subtitlesSrt: srt),
          );
      if (mounted) showShortsSnackBar(context, 'Altyazı taslağı oluşturuldu.');
    });
  }

  Future<void> _pickContentRating(ShortContentRating current) async {
    final picked = await showModalBottomSheet<ShortContentRating>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final v in ShortContentRating.values)
              ListTile(title: Text(v.label), onTap: () => Navigator.pop(ctx, v)),
          ],
        ),
      ),
    );
    if (picked != null) {
      ref.read(shortUploadDraftProvider.notifier).patch(
            (d) => d.copyWith(contentRating: picked),
          );
    }
  }

  Future<void> _pickThumbnail(String path) async {
    ref.read(shortUploadDraftProvider.notifier).patch(
          (d) => d.copyWith(thumbnailPath: path),
        );
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
    final thumb = draft.thumbnailPath?.trim();
    if (thumb == null || thumb.isEmpty || !File(thumb).existsSync()) {
      setState(() => _error = 'Lütfen kapak görseli seçin.');
      showShortsSnackBar(context, 'Video yüklemeden önce kapak görseli seçmelisiniz.');
      return;
    }
    final descError = ContentGuard.validate(draft.description, maxLen: 2200);
    if (descError != null) {
      setState(() => _error = descError);
      showShortsSnackBar(context, descError);
      return;
    }
    final copyrightError = ShortCopyrightGuard.validateExternalAudio(null);
    if (copyrightError != null) {
      setState(() => _error = copyrightError);
      showShortsSnackBar(context, copyrightError);
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
      await FirebaseBootstrap.logEvent(
        'short_publish',
        parameters: {
          if (draft.duetOfId != null) 'duet_of': draft.duetOfId!,
          if (draft.remixOfId != null) 'remix_of': draft.remixOfId!,
        },
      );
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
            onPressed: (_uploading || _savingDraft) ? null : _saveDraft,
            child: _savingDraft
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Taslak'),
          ),
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
          const SizedBox(height: 8),
          Text(
            'Yapay zekâ',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: _aiLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome, size: 18),
                label: const Text('Özet + hashtag'),
                onPressed: _aiLoading ? null : _aiSuggestAll,
              ),
              ActionChip(
                label: const Text('Altyazı'),
                onPressed: _aiLoading ? null : _aiGenerateSubtitles,
              ),
              ActionChip(
                label: const Text('Kapak öner'),
                onPressed: _aiLoading ? null : () => _aiGenerateThumbnails(),
              ),
              ActionChip(
                label: const Text('Müzik öner'),
                onPressed: _aiLoading ? null : _aiRecommendMusic,
              ),
            ],
          ),
          if (draft.aiSummary != null && draft.aiSummary!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'AI özeti: ${draft.aiSummary}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          if (draft.thumbnailCandidates.isNotEmpty) ...[
            const SizedBox(height: 12),
            StudioCoverPicker(
              candidates: draft.thumbnailCandidates,
              selectedPath: draft.thumbnailPath,
              loading: _aiLoading,
              onSelected: _pickThumbnail,
              onGenerate: () => _aiGenerateThumbnails(),
            ),
          ],
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
                    final list = await ref
                        .read(shortsRepositoryProvider)
                        .searchMusic(q)
                        .catchError((_) => const <ShortMusicEntity>[]);
                    final merged = _musicWithFallback(list);
                    if (mounted) setState(() => _musicHits = merged);
                    return merged;
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
            title: const Text('İçerik derecesi'),
            subtitle: Text(draft.contentRating.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickContentRating(draft.contentRating),
          ),
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
          const ListTile(
            leading: Icon(Icons.copyright_outlined, color: Colors.white54),
            title: Text('Telif koruması'),
            subtitle: Text(
              ShortCopyrightGuard.catalogOnlyHint,
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
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

  Future<void> _addExternalMusic() async {
    final urlCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    final picked = await showDialog<ShortMusicEntity>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bağlantıdan müzik ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'YouTube / müzik bağlantısı',
                hintText: 'https://...',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Başlık'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () {
              final url = urlCtrl.text.trim();
              if (!url.startsWith('http://') && !url.startsWith('https://')) {
                return;
              }
              final title = titleCtrl.text.trim();
              Navigator.pop(
                ctx,
                ShortMusicEntity(
                  id: 'external:${Uri.encodeComponent(url)}',
                  title: title.isEmpty ? _platformTitle(url) : title,
                  artist: _platformTitle(url),
                  audioUrl: url,
                ),
              );
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    urlCtrl.dispose();
    titleCtrl.dispose();
    if (picked != null && mounted) Navigator.pop(context, picked);
  }

  static String _platformTitle(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    if (host.contains('youtube') || host.contains('youtu.be')) {
      return 'YouTube müziği';
    }
    if (host.contains('soundcloud')) return 'SoundCloud müziği';
    if (host.contains('spotify')) return 'Spotify bağlantısı';
    return 'Harici müzik';
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
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.link_rounded),
            title: const Text('YouTube / başka platformdan ekle'),
            subtitle: const Text('Bağlantı ve başlık gir'),
            onTap: _addExternalMusic,
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
