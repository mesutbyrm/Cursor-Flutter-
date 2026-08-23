import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import 'package:canlifal_social/core/providers/auth_selectors.dart';
import 'package:canlifal_social/core/theme/app_colors.dart';

import '../../data/short_upload_draft_store.dart';
import '../../domain/entities/short_upload_draft.dart';
import '../utils/shorts_api_message.dart';
import '../utils/short_studio_launch.dart';
import 'short_studio_providers.dart';
import 'studio_compose_page.dart';
import 'studio_editor_page.dart';
import 'studio_publish_page.dart';

const int kShortStudioMaxVideoBytes = 20 * 1024 * 1024;
const Duration kShortStudioMaxVideoDuration = Duration(seconds: 30);

enum _StudioStep { pick, edit, compose, publish }

/// TikTok tarzı video stüdyosu — seç → düzenle → yazı/sticker → yayınla.
class ShortsStudioPage extends ConsumerStatefulWidget {
  const ShortsStudioPage({super.key, this.launchParams});

  final ShortStudioLaunchParams? launchParams;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      if (mounted) showShortsSnackBar(context, 'Video yüklemek için giriş yapın.');
      if (mounted) context.pop();
      return;
    }

    final launch = widget.launchParams ?? const ShortStudioLaunchParams();
    await applyStudioLaunchParams(ref, launch);

    final draft = ref.read(shortUploadDraftProvider);
    if (draft.sourcePath != null) {
      if (mounted) setState(() => _step = _StudioStep.edit);
      return;
    }

    if (launch.mode != ShortStudioMode.normal) {
      await _pickFromGallery();
      return;
    }

    final metas = await ShortUploadDraftStore.instance.listForUser(userId);
    if (!mounted) return;
    if (metas.isNotEmpty) {
      final action = await showModalBottomSheet<Object?>(
        context: context,
        backgroundColor: const Color(0xFF121218),
        isScrollControlled: true,
        builder: (ctx) => _DraftEntrySheet(metas: metas),
      );
      if (!mounted) return;
      if (action == 'new') {
        await _pickFromGallery();
      } else if (action is String && action != 'new') {
        final loaded = await ShortUploadDraftStore.instance.load(action);
        if (!mounted) return;
        if (loaded == null) {
          showShortsSnackBar(context, 'Taslak dosyası bulunamadı.');
          await _pickFromGallery();
          return;
        }
        ref.read(shortUploadDraftProvider.notifier).loadDraft(loaded);
        setState(() => _step = loaded.editedPath != null
            ? _StudioStep.compose
            : _StudioStep.edit);
      } else {
        context.pop();
      }
      return;
    }

    await _pickFromGallery();
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
        maxDuration: kShortStudioMaxVideoDuration,
      );
      if (file == null) {
        if (mounted) context.pop();
        return;
      }
      final error = await _validatePickedVideo(file.path);
      if (error != null) {
        if (mounted) showShortsSnackBar(context, error);
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

  Future<String?> _validatePickedVideo(String path) async {
    final file = File(path);
    final size = await file.length();
    if (size > kShortStudioMaxVideoBytes) {
      return 'Video en fazla 20 MB olabilir.';
    }
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(file);
      await controller.initialize();
      if (controller.value.duration > kShortStudioMaxVideoDuration) {
        return 'Video en fazla 30 saniye olabilir.';
      }
    } catch (_) {
      // Süre okunamazsa editör yine açılır; export aşaması 30 saniye ile sınırlar.
      return null;
    } finally {
      await controller?.dispose();
    }
    return null;
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
    final launchLabel = switch (widget.launchParams?.mode) {
      ShortStudioMode.duet => 'Düet modu${draft.sourceVideoTitle != null ? ' — ${draft.sourceVideoTitle}' : ''}',
      ShortStudioMode.remix => 'Remix modu${draft.musicTitle != null ? ' — ${draft.musicTitle}' : ''}',
      ShortStudioMode.liveClip => 'Canlı fal / yayın klibi',
      ShortStudioMode.videoReply => 'Video yanıt${draft.sourceVideoTitle != null ? ' — ${draft.sourceVideoTitle}' : ''}',
      _ => null,
    };

    if (path == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Video Stüdyosu')),
        body: Column(
          children: [
            if (launchLabel != null)
              MaterialBanner(
                content: Text(launchLabel),
                leading: const Icon(Icons.info_outline),
                actions: const [SizedBox.shrink()],
              ),
            Expanded(
              child: Center(
                child: FilledButton(
                  onPressed: _pickFromGallery,
                  child: const Text('Galeriden video seç'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (launchLabel != null)
          MaterialBanner(
            content: Text(launchLabel),
            leading: const Icon(Icons.info_outline),
            actions: const [SizedBox.shrink()],
          ),
        Expanded(
          child: switch (_step) {
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
          },
        ),
      ],
    );
  }
}

class _DraftEntrySheet extends ConsumerWidget {
  const _DraftEntrySheet({required this.metas});

  final List<ShortSavedDraftMeta> metas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Taslaklar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: ListView.separated(
                itemCount: metas.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final meta = metas[i];
                  final saved = DateTime.fromMillisecondsSinceEpoch(meta.savedAtMs);
                  return ListTile(
                    leading: const Icon(Icons.drafts_outlined, color: Colors.white70),
                    title: Text(
                      meta.previewLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${saved.day}.${saved.month}.${saved.year} ${saved.hour.toString().padLeft(2, '0')}:${saved.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.white54),
                      onPressed: () async {
                        await ShortUploadDraftStore.instance.delete(meta.id);
                        ref.invalidate(
                          shortSavedDraftsProvider(meta.userId),
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                    onTap: () => Navigator.pop(context, meta.id),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, 'new'),
              icon: const Icon(Icons.add),
              label: const Text('Yeni video'),
            ),
          ],
        ),
      ),
    );
  }
}
