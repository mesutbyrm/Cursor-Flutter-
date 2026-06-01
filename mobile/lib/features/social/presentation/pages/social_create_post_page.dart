import 'dart:io';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/create_social_post_input.dart';
import '../providers/social_create_post_provider.dart';

/// Instagram tarzı yeni gönderi — görsel önizleme + açıklama + Paylaş.
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
  var _submitting = false;

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
      (_caption.text.trim().isNotEmpty || _imagePath != null);

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 88,
      );
      if (file != null && mounted) {
        setState(() => _imagePath = file.path);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görsel seçilemedi: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_canShare) return;
    setState(() => _submitting = true);
    try {
      await ref.read(socialCreatePostProvider.notifier).submit(
            CreateSocialPostInput(
              caption: _caption.text.trim(),
              imagePath: _imagePath,
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

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authControllerProvider).valueOrNull;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(8, top + 6, 12, 10),
            decoration: BoxDecoration(
              color: context.scaffoldBg,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            child: Row(
              children: [
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).maybePop(),
                  child: Text(
                    'İptal',
                    style: TextStyle(
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Yeni gönderi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _canShare ? _submit : null,
                  child: _submitting
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          'Paylaş',
                          style: TextStyle(
                            color: _canShare
                                ? AppThemeColors.accentPink
                                : context.colors.onSurfaceMuted,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _MediaPreview(
                    imagePath: _imagePath,
                    onPickGallery: () => _pickImage(ImageSource.gallery),
                    onPickCamera: () => _pickImage(ImageSource.camera),
                    onClear: () => setState(() => _imagePath = null),
                  ),
                  SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserAvatar(url: me?.avatarUrl, radius: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _caption,
                          maxLines: 8,
                          maxLength: 2200,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.45,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Bir açıklama yaz…',
                            hintStyle: TextStyle(
                              color: context.colors.onSurfaceMuted.withValues(alpha: 0.9),
                            ),
                            border: InputBorder.none,
                            counterStyle: TextStyle(
                              color: context.colors.onSurfaceMuted,
                              fontSize: 11,
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  _OptionTile(
                    icon: Icons.photo_outlined,
                    label: 'Galeriden seç',
                    onTap: () => _pickImage(ImageSource.gallery),
                  ),
                  _OptionTile(
                    icon: Icons.photo_camera_outlined,
                    label: 'Fotoğraf çek',
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                  _OptionTile(
                    icon: Icons.location_on_outlined,
                    label: 'Konum ekle',
                    muted: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Konum yakında')),
                      );
                    },
                  ),
                  _OptionTile(
                    icon: Icons.tag_faces_outlined,
                    label: 'Kişileri etiketle',
                    muted: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Etiketleme yakında')),
                      );
                    },
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
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onClear,
  });

  final String? imagePath;
  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.file(
                File(imagePath!),
                fit: BoxFit.cover,
              ),
            ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PickChip(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  onTap: onPickGallery,
                ),
                SizedBox(width: 12),
                _PickChip(
                  icon: Icons.photo_camera_rounded,
                  label: 'Kamera',
                  onTap: onPickCamera,
                ),
              ],
            ),
          ],
        ),
      ),
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.muted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: muted ? context.colors.onSurfaceMuted : context.colors.onSurface,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: muted ? context.colors.onSurfaceMuted : context.colors.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: context.colors.onSurfaceMuted.withValues(alpha: 0.6),
      ),
      onTap: onTap,
    );
  }
}
