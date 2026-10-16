import 'dart:io';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../search/domain/entities/search_user_entity.dart';
import '../../domain/entities/create_social_post_input.dart';
import '../providers/social_create_post_provider.dart';
import '../utils/social_post_location_helper.dart';
import '../widgets/social_mention_picker_sheet.dart';
import '../widgets/social_local_video_preview.dart';
import 'package:go_router/go_router.dart';

/// Instagram tarzı yeni gönderi — görsel/video önizleme + açıklama + Paylaş.
class SocialCreatePostPage extends ConsumerStatefulWidget {
  const SocialCreatePostPage({super.key, this.initialCaption});

  final String? initialCaption;

  @override
  ConsumerState<SocialCreatePostPage> createState() =>
      _SocialCreatePostPageState();
}

class _SocialCreatePostPageState extends ConsumerState<SocialCreatePostPage> {
  final _caption = TextEditingController();
  final _picker = ImagePicker();
  String? _imagePath;
  String? _videoPath;
  String? _locationLabel;
  var _submitting = false;
  var _locationLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCaption != null) {
      _caption.text = widget.initialCaption!;
    }
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
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
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel seçilemedi: $e')),
      );
    }
  }

  /// Sosyal akış yalnız metin/foto destekler; video Kısa Videolar'dan
  /// paylaşılır (önceden video seçilip gönderilince hata veriyordu).
  Future<void> _pickVideo() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video paylaşımı Kısa Videolar bölümünden yapılır.'),
      ),
    );
    context.push('/shorts/upload');
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
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_canShare) return;
    setState(() => _submitting = true);
    try {
      await ref.read(socialCreatePostProvider.notifier).submit(
            CreateSocialPostInput(
              // Konum etiketi gönderi metnine eklenir (sunucuda ayrı alan yok).
              // Konum metne bir kez eklenir (önceden iki kez «📍» çıkıyordu).
              caption: _locationLabel != null &&
                      _locationLabel!.trim().isNotEmpty &&
                      !_caption.text.contains('📍')
                  ? '${_caption.text.trim()}\n📍 ${_locationLabel!.trim()}'.trim()
                  : _caption.text.trim(),
              imagePath: _imagePath,
              videoPath: _videoPath,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paylaşım yayınlandı')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static const _suggestTags = [
    '#GirLive',
    '#Keşfet',
    '#Fal',
    '#Tarot',
    '#KahveFalı',
    '#Günaydın',
    '#Aşk',
    '#Burç',
  ];

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider).valueOrNull;
    final top = MediaQuery.paddingOf(context).top;
    final len = _caption.text.characters.length;

    Widget action(IconData icon, String label, List<Color> colors, VoidCallback? onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: context.colors.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(4, top + 6, 12, 10),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Kapat',
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close_rounded, size: 26),
                ),
                const Expanded(
                  child: Text(
                    'Yeni gönderi',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: _canShare ? 1 : 0.45,
                  child: GestureDetector(
                    onTap: _canShare ? _submit : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFE2C55), Color(0xFFB832FF)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: _canShare
                            ? const [
                                BoxShadow(
                                  color: Color(0x66FE2C55),
                                  blurRadius: 14,
                                  offset: Offset(0, 4),
                                ),
                              ]
                            : null,
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
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Yazar + görünürlük
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF25F4EE), Color(0xFFFE2C55)],
                          ),
                        ),
                        child: UserAvatar(url: me?.avatarUrl, radius: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              me?.display ?? 'Sen',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.colors.primary.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '🌍 Herkese açık · Keşfet\'te görünebilir',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Açıklama kartı
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: context.colors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _caption,
                          minLines: 4,
                          maxLines: 10,
                          maxLength: 2200,
                          style: const TextStyle(fontSize: 16.5, height: 1.45),
                          decoration: InputDecoration(
                            hintText: 'Ne paylaşmak istersin? @kişi ve #etiket ekleyebilirsin…',
                            hintStyle: TextStyle(color: context.colors.onSurfaceMuted),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        Row(
                          children: [
                            if (_locationLabel != null)
                              Flexible(
                                child: InputChip(
                                  avatar: const Icon(Icons.location_on_rounded, size: 16),
                                  label: Text(
                                    _locationLabel!,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onDeleted: () => setState(() => _locationLabel = null),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            const Spacer(),
                            Text(
                              '$len/2200',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: len > 2000
                                    ? AppThemeColors.accentPink
                                    : context.colors.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Önerilen etiketler
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _suggestTags.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) => ActionChip(
                        label: Text(_suggestTags[i]),
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _insertText('${_suggestTags[i]} '),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _MediaPreview(
                    imagePath: _imagePath,
                    videoPath: _videoPath,
                    onPickGallery: () => _pickImage(ImageSource.gallery),
                    onPickCamera: () => _pickImage(ImageSource.camera),
                    onPickVideo: _pickVideo,
                    onClear: () => setState(() {
                      _imagePath = null;
                      _videoPath = null;
                    }),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Gönderine ekle',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 16,
                    spacing: 12,
                    children: [
                      action(Icons.photo_library_rounded, 'Galeri',
                          const [Color(0xFF22C55E), Color(0xFF0EA5E9)],
                          () => _pickImage(ImageSource.gallery)),
                      action(Icons.photo_camera_rounded, 'Kamera',
                          const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          () => _pickImage(ImageSource.camera)),
                      action(Icons.videocam_rounded, 'Video',
                          const [Color(0xFFFE2C55), Color(0xFFFF8A00)], _pickVideo),
                      action(
                          Icons.location_on_rounded,
                          _locationLoading ? 'Konum…' : 'Konum',
                          const [Color(0xFFF59E0B), Color(0xFFEF4444)],
                          _locationLoading ? null : _addLocation),
                      action(Icons.alternate_email_rounded, 'Etiketle',
                          const [Color(0xFF06B6D4), Color(0xFF3B82F6)], _pickMention),
                      action(Icons.tag_rounded, 'Hashtag',
                          const [Color(0xFFEC4899), Color(0xFFB832FF)],
                          () => _insertText('#')),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: context.colors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'İpucu: Görselli ve etiketli paylaşımlar Keşfet\'te daha çok görünür. '
                            'Kısa videolar için «Video»ya dokun.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({
    required this.imagePath,
    required this.videoPath,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onPickVideo,
    required this.onClear,
  });

  final String? imagePath;
  final String? videoPath;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onPickVideo;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return _MediaFrame(
        onClear: onClear,
        child: Image.file(File(imagePath!), fit: BoxFit.cover),
      );
    }
    if (videoPath != null) {
      return _MediaFrame(
        onClear: onClear,
        child: SocialLocalVideoPreview(videoPath: videoPath!),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppThemeColors.accentPurple.withValues(alpha: 0.25),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 56,
              color: context.colors.onSurfaceMuted.withValues(alpha: 0.8),
            ),
            SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                _PickChip(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  onTap: onPickGallery,
                ),
                _PickChip(
                  icon: Icons.photo_camera_rounded,
                  label: 'Kamera',
                  onTap: onPickCamera,
                ),
                _PickChip(
                  icon: Icons.videocam_rounded,
                  label: 'Video',
                  onTap: onPickVideo,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaFrame extends StatelessWidget {
  const _MediaFrame({required this.child, required this.onClear});

  final Widget child;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(aspectRatio: 1, child: child),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.black54,
            shape: const CircleBorder(),
            child: IconButton(
              icon: Icon(Icons.close_rounded, color: Colors.white),
              onPressed: onClear,
            ),
          ),
        ),
      ],
    );
  }
}

class _PickChip extends StatelessWidget {
  const _PickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppThemeColors.accentPink.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: AppThemeColors.accentPink),
              SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppThemeColors.accentPink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

