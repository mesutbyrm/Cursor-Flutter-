import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../data/services/short_video_upload_service.dart';
import '../../domain/entities/short_video_entity.dart';
import '../providers/shorts_providers.dart';
import '../utils/shorts_api_message.dart';

/// Video sahibi veya admin: kapak görseli, açıklama ve yayın ayarlarını
/// düzenler (`PATCH /api/short-videos/{id}`). Kaydedilirse güncel video döner.
Future<ShortVideoEntity?> showShortVideoEditSheet(
  BuildContext context,
  ShortVideoEntity video, {
  bool asAdmin = false,
}) {
  return showModalBottomSheet<ShortVideoEntity>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: const Color(0xFF121218),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ShortVideoEditSheet(video: video, asAdmin: asAdmin),
  );
}

const kShortVisibilityOptions = <(String, String)>[
  ('everyone', 'Herkes'),
  ('followers', 'Takipçiler'),
  ('close_friends', 'Yakın arkadaşlar'),
  ('private', 'Sadece ben'),
];

const kShortCommentOptions = <(String, String)>[
  ('everyone', 'Herkes'),
  ('followers', 'Takipçiler'),
  ('off', 'Kapalı'),
];

class ShortVideoEditSheet extends ConsumerStatefulWidget {
  const ShortVideoEditSheet({
    super.key,
    required this.video,
    this.asAdmin = false,
  });

  final ShortVideoEntity video;
  final bool asAdmin;

  @override
  ConsumerState<ShortVideoEditSheet> createState() =>
      _ShortVideoEditSheetState();
}

class _ShortVideoEditSheetState extends ConsumerState<ShortVideoEditSheet> {
  late final TextEditingController _desc;
  late final TextEditingController _location;
  late String _visibility;
  late String _commentSetting;
  late bool _allowDuet;
  String? _newCoverPath;
  double _frameSec = 0;
  var _grabbing = false;
  var _saving = false;

  ShortVideoEntity get v => widget.video;

  @override
  void initState() {
    super.initState();
    _desc = TextEditingController(text: v.description ?? '');
    _location = TextEditingController(text: v.locationName ?? '');
    _visibility = kShortVisibilityOptions.any((o) => o.$1 == v.visibility)
        ? v.visibility
        : 'everyone';
    _commentSetting = kShortCommentOptions.any((o) => o.$1 == v.commentSetting)
        ? v.commentSetting
        : 'everyone';
    _allowDuet = v.allowDuet;
  }

  @override
  void dispose() {
    _desc.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;
    setState(() => _newCoverPath = picked.path);
  }

  Future<void> _grabFrame() async {
    if (_grabbing) return;
    setState(() => _grabbing = true);
    try {
      final path = await VideoThumbnail.thumbnailFile(
        video: v.videoUrl,
        imageFormat: ImageFormat.JPEG,
        timeMs: (_frameSec * 1000).round(),
        maxWidth: 720,
        quality: 85,
      );
      if (!mounted) return;
      if (path == null) {
        showShortsSnackBar(context, 'Kare alınamadı. Galeriden seçebilirsiniz.');
        return;
      }
      setState(() => _newCoverPath = path);
    } catch (_) {
      if (mounted) {
        showShortsSnackBar(context, 'Kare alınamadı. Galeriden seçebilirsiniz.');
      }
    } finally {
      if (mounted) setState(() => _grabbing = false);
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      String? thumbUrl;
      final cover = _newCoverPath;
      if (cover != null) {
        thumbUrl =
            await ref.read(shortVideoUploadServiceProvider).uploadThumbnail(cover);
      }
      final desc = _desc.text.trim();
      final loc = _location.text.trim();
      final updated = await ref.read(shortsRemoteProvider).updateVideo(
            v.id,
            description: desc != (v.description ?? '').trim() ? desc : null,
            thumbnailUrl: thumbUrl,
            visibility: _visibility != v.visibility ? _visibility : null,
            commentSetting:
                _commentSetting != v.commentSetting ? _commentSetting : null,
            allowDuet: _allowDuet != v.allowDuet ? _allowDuet : null,
            locationName: loc != (v.locationName ?? '').trim() ? loc : null,
          );
      if (!mounted) return;
      Navigator.of(context).pop(updated);
    } catch (e) {
      if (mounted) showShortsSnackBar(context, shortsErrorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _dirty =>
      _newCoverPath != null ||
      _desc.text.trim() != (v.description ?? '').trim() ||
      _location.text.trim() != (v.locationName ?? '').trim() ||
      _visibility != v.visibility ||
      _commentSetting != v.commentSetting ||
      _allowDuet != v.allowDuet;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final maxSec = (v.durationSec ?? 0) > 0 ? v.durationSec! : 15.0;
    const label = TextStyle(
      color: Colors.white70,
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
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
            Text(
              widget.asAdmin ? 'Videoyu düzenle (admin)' : 'Videoyu düzenle',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            const Text('Kapak görseli', style: label),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CoverPreview(
                  localPath: _newCoverPath,
                  networkUrl: v.displayThumbnailUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        key: const Key('short-edit-gallery'),
                        onPressed: _saving ? null : _pickFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galeriden seç'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Videodan kare: ${_frameSec.toStringAsFixed(1)} sn',
                        style: label,
                      ),
                      Slider(
                        value: _frameSec.clamp(0, maxSec),
                        max: maxSec,
                        onChanged: _saving
                            ? null
                            : (x) => setState(() => _frameSec = x),
                      ),
                      OutlinedButton.icon(
                        key: const Key('short-edit-frame'),
                        onPressed: _saving || _grabbing ? null : _grabFrame,
                        icon: _grabbing
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.movie_filter_outlined),
                        label: const Text('Bu kareyi kapak yap'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Açıklama', style: label),
            const SizedBox(height: 6),
            TextField(
              key: const Key('short-edit-description'),
              controller: _desc,
              maxLength: 500,
              maxLines: 3,
              minLines: 2,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Açıklama, #etiket ve @bahsetme ekleyin',
              ),
            ),
            const SizedBox(height: 6),
            const Text('Konum', style: label),
            const SizedBox(height: 6),
            TextField(
              controller: _location,
              maxLength: 120,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Örn. İstanbul'),
            ),
            const SizedBox(height: 6),
            const Text('Kimler izleyebilir', style: label),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final o in kShortVisibilityOptions)
                  ChoiceChip(
                    label: Text(o.$2),
                    selected: _visibility == o.$1,
                    onSelected: _saving
                        ? null
                        : (_) => setState(() => _visibility = o.$1),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Yorumlar', style: label),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final o in kShortCommentOptions)
                  ChoiceChip(
                    label: Text(o.$2),
                    selected: _commentSetting == o.$1,
                    onSelected: _saving
                        ? null
                        : (_) => setState(() => _commentSetting = o.$1),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _allowDuet,
              onChanged:
                  _saving ? null : (x) => setState(() => _allowDuet = x),
              title: const Text(
                'Düet / remix izni',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: const Key('short-edit-save'),
              onPressed: _saving || !_dirty ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({this.localPath, this.networkUrl});

  final String? localPath;
  final String? networkUrl;

  @override
  Widget build(BuildContext context) {
    final Widget img;
    if (localPath != null) {
      img = Image.file(File(localPath!), fit: BoxFit.cover);
    } else if (networkUrl != null && networkUrl!.isNotEmpty) {
      img = Image.network(
        networkUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const _NoCover(),
      );
    } else {
      img = const _NoCover();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(width: 96, height: 160, child: img),
    );
  }
}

class _NoCover extends StatelessWidget {
  const _NoCover();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF26262E),
      child: Center(
        child: Text(
          'Kapak yok',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ),
    );
  }
}
