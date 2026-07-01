import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:canlifal_social/core/providers/auth_selectors.dart';
import 'package:canlifal_social/core/theme/app_colors.dart';

import '../utils/shorts_api_message.dart';
import 'short_studio_providers.dart';
import 'studio_compose_page.dart';
import 'studio_editor_page.dart';
import 'studio_publish_page.dart';

enum _StudioStep { pick, edit, compose, publish }

/// TikTok tarzı video stüdyosu — seç → düzenle → yazı/sticker → yayınla.
class ShortsStudioPage extends ConsumerStatefulWidget {
  const ShortsStudioPage({super.key});

  @override
  ConsumerState<ShortsStudioPage> createState() => _ShortsStudioPageState();
}

class _ShortsStudioPageState extends ConsumerState<ShortsStudioPage> {
  _StudioStep _step = _StudioStep.pick;
  final _picker = ImagePicker();
  var _picking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final draft = ref.read(shortUploadDraftProvider);
      if (draft.sourcePath != null) {
        setState(() => _step = _StudioStep.edit);
      } else {
        _pickFromGallery();
      }
    });
  }

  Future<void> _pickFromGallery() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      if (mounted) showShortsSnackBar(context, 'Video yüklemek için giriş yapın.');
      if (mounted) context.pop();
      return;
    }
    setState(() => _picking = true);
    try {
      final file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );
      if (file == null) {
        if (mounted) context.pop();
        return;
      }
      ref.read(shortUploadDraftProvider.notifier).setSource(file.path);
      if (mounted) setState(() => _step = _StudioStep.edit);
    } catch (e) {
      if (mounted) showShortsSnackBar(context, 'Video seçilemedi: $e');
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _goCompose() => setState(() => _step = _StudioStep.compose);
  void _goPublish() => setState(() => _step = _StudioStep.publish);

  @override
  Widget build(BuildContext context) {
    if (_picking || _step == _StudioStep.pick) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Video Stüdyosu'),
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentPurple),
        ),
      );
    }

    final draft = ref.watch(shortUploadDraftProvider);
    final path = draft.sourcePath;
    if (path == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video Stüdyosu')),
        body: Center(
          child: FilledButton(
            onPressed: _pickFromGallery,
            child: const Text('Galeriden video seç'),
          ),
        ),
      );
    }

    return switch (_step) {
      _StudioStep.edit => StudioEditorPage(
          onNext: _goCompose,
          onBack: () {
            ref.read(shortUploadDraftProvider.notifier).reset();
            context.pop();
          },
        ),
      _StudioStep.compose => StudioComposePage(
          onNext: _goPublish,
          onBack: () => setState(() => _step = _StudioStep.edit),
        ),
      _StudioStep.publish => StudioPublishPage(
          onBack: _goCompose,
          onPublished: () {
            ref.read(shortUploadDraftProvider.notifier).reset();
            context.go('/shorts');
          },
        ),
      _ => const SizedBox.shrink(),
    };
  }
}
