import 'dart:io';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/network/api_exception.dart';
import '../../../../../core/widgets/user_avatar.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../search/domain/entities/search_user_entity.dart';
import '../../../domain/entities/create_social_post_input.dart';
import '../../providers/social_composer_providers.dart';
import '../../providers/social_create_post_provider.dart';
import '../social_mention_picker_sheet.dart';
import '../social_local_video_preview.dart';
import '../../utils/social_post_location_helper.dart';

/// Sosyal akış üstü — aynı sayfada paylaşım (metin, foto, video, duygu, #, @).
class SocialFeedComposer extends ConsumerStatefulWidget {
  const SocialFeedComposer({super.key, this.onPostPublished});

  /// Başarılı inline paylaşımdan sonra (ör. akışı üste kaydır).
  final VoidCallback? onPostPublished;

  @override
  ConsumerState<SocialFeedComposer> createState() => _SocialFeedComposerState();
}

class _SocialFeedComposerState extends ConsumerState<SocialFeedComposer> {
  final _caption = TextEditingController();
  final _picker = ImagePicker();
  final _focus = FocusNode();

  var _expanded = false;
  var _submitting = false;
  String? _imagePath;
  String? _videoPath;
  String? _moodEmoji;
  String? _locationLabel;
  var _locationLoading = false;

  static const _moods = ['😊', '😍', '🔥', '✨', '😢', '🎉', '💜', '🙏'];

  @override
  void dispose() {
    _caption.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _expand() {
    setState(() => _expanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  bool get _canShare =>
      !_submitting &&
      (_caption.text.trim().isNotEmpty ||
          _imagePath != null ||
          _videoPath != null);

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );
      if (file != null && mounted) {
        setState(() {
          _imagePath = file.path;
          _videoPath = null;
          _expanded = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel seçilemedi: $e')),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 3),
      );
      if (file != null && mounted) {
        setState(() {
          _videoPath = file.path;
          _imagePath = null;
          _expanded = true;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Video seçilemedi: $e')),
      );
    }
  }

  void _insertText(String snippet) {
    final text = _caption.text;
    final sel = _caption.selection;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final next = text.replaceRange(start, end, snippet);
    _caption.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: start + snippet.length),
    );
    setState(() {});
    _expand();
  }

  Future<void> _pickMention() async {
    final picked = await showModalBottomSheet<SearchUserEntity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF120A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const SocialMentionPickerSheet(),
    );
    if (picked != null) {
      _insertText('@${picked.username} ');
    }
  }

  Future<void> _addLocation() async {
    if (_locationLoading) return;
    setState(() => _locationLoading = true);
    try {
      final result = await pickSocialPostLocationLabel();
      if (!mounted) return;
      if (!result.ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'Konum alınamadı')),
        );
        return;
      }
      final label = result.label!;
      setState(() => _locationLabel = label);
      if (!_caption.text.contains('📍')) {
        _insertText('${formatSocialPostLocationSnippet(label)} ');
      }
      _expand();
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _submit() async {
    final me = ref.read(authControllerProvider).valueOrNull;
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşım için giriş yapın')),
      );
      return;
    }
    if (!_canShare) return;

    var caption = _caption.text.trim();
    if (_moodEmoji != null && _moodEmoji!.isNotEmpty) {
      caption = caption.isEmpty ? _moodEmoji! : '$_moodEmoji $caption';
    }

    setState(() => _submitting = true);
    try {
      await ref.read(socialCreatePostProvider.notifier).submit(
            CreateSocialPostInput(
              caption: caption,
              imagePath: _imagePath,
              videoPath: _videoPath,
            ),
          );
      if (!mounted) return;
      _caption.clear();
      setState(() {
        _imagePath = null;
        _videoPath = null;
        _moodEmoji = null;
        _locationLabel = null;
        _expanded = false;
      });
      _focus.unfocus();
      widget.onPostPublished?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşım yayınlandı')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(socialComposerExpandedProvider, (prev, next) {
      if (next == true && mounted) {
        _expand();
        ref.read(socialComposerExpandedProvider.notifier).state = false;
      }
    });

    final isLoggedIn = ref.watch(
      authControllerProvider.select((a) => a.valueOrNull != null),
    );
    final me = ref.watch(
      authControllerProvider.select(
        (a) => (a.valueOrNull?.avatarUrl, a.valueOrNull?.display),
      ),
    );
    final displayName = me.$2 ?? 'sen';
    final avatarUrl = me.$1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF12122A).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppThemeColors.accentPurple.withValues(alpha: 0.38),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppThemeColors.accentPurple.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(url: avatarUrl, radius: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _expanded
                        ? TextField(
                            controller: _caption,
                            focusNode: _focus,
                            maxLines: 5,
                            minLines: 2,
                            maxLength: 2200,
                            style: TextStyle(
                              color: context.colors.onSurface,
                              fontSize: 15,
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ne düşünüyorsun, $displayName?',
                              hintStyle: TextStyle(
                                color: context.colors.onSurfaceMuted
                                    .withValues(alpha: 0.9),
                              ),
                              border: InputBorder.none,
                              counterStyle: TextStyle(
                                color: context.colors.onSurfaceMuted,
                                fontSize: 11,
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          )
                        : GestureDetector(
                            onTap: !isLoggedIn
                                ? () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Paylaşım için giriş yapın'),
                                      ),
                                    );
                                  }
                                : _expand,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  'Ne düşünüyorsun, $displayName?',
                                  style: TextStyle(
                                    color: context.colors.onSurfaceMuted
                                        .withValues(alpha: 0.95),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            if (_moodEmoji != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text('Duygu: $_moodEmoji'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _moodEmoji = null),
                  ),
                ),
              ),
            if (_locationLabel != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    avatar: const Icon(Icons.location_on_rounded, size: 16),
                    label: Text(_locationLabel!),
                    onDeleted: () => setState(() => _locationLabel = null),
                  ),
                ),
              ),
            if (_imagePath != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: _MediaPreview(
                  child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                  onClear: () => setState(() => _imagePath = null),
                ),
              ),
            if (_videoPath != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                child: _MediaPreview(
                  child: SocialLocalVideoPreview(videoPath: _videoPath!),
                  onClear: () => setState(() => _videoPath = null),
                ),
              ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: [
                  _ComposerAction(
                    icon: Icons.photo_library_rounded,
                    label: 'Foto',
                    color: AppThemeColors.accentPink,
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  _ComposerAction(
                    icon: Icons.videocam_rounded,
                    label: 'Video',
                    color: const Color(0xFFE85D4A),
                    onTap: _pickVideo,
                  ),
                  _ComposerAction(
                    icon: Icons.emoji_emotions_outlined,
                    label: 'Duygu',
                    color: const Color(0xFFF7B928),
                    onTap: _showMoodPicker,
                  ),
                  IconButton(
                    tooltip: 'Hashtag',
                    onPressed: () => _insertText('#'),
                    icon: const Icon(Icons.tag_rounded, size: 22),
                    color: AppThemeColors.accentPurple,
                  ),
                  IconButton(
                    tooltip: 'Etiketle',
                    onPressed: _pickMention,
                    icon: const Icon(Icons.alternate_email_rounded, size: 22),
                    color: AppThemeColors.accentCyan,
                  ),
                  IconButton(
                    tooltip: 'Konum',
                    onPressed: _locationLoading ? null : _addLocation,
                    icon: _locationLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.location_on_outlined, size: 22),
                    color: AppThemeColors.onlineGreen,
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _canShare ? _submit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppThemeColors.accentPink,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: const Size(0, 36),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Paylaş',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoodPicker() {
    _expand();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF120A24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _moods.map((e) {
              return InkWell(
                onTap: () {
                  setState(() => _moodEmoji = e);
                  Navigator.pop(ctx);
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(e, style: const TextStyle(fontSize: 32)),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.child, required this.onClear});

  final Widget child;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(aspectRatio: 16 / 9, child: child),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: onClear,
            ),
          ),
        ),
      ],
    );
  }
}

class _ComposerAction extends StatelessWidget {
  const _ComposerAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
