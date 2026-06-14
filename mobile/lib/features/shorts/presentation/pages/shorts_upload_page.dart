import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/providers/auth_selectors.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/shorts_providers.dart';

const _maxDurationSec = 15.0;
const _maxBytes = 10 * 1024 * 1024;

/// Galeriden video seç, önizle, açıklama ekle ve yükle.
class ShortsUploadPage extends ConsumerStatefulWidget {
  const ShortsUploadPage({super.key});

  @override
  ConsumerState<ShortsUploadPage> createState() => _ShortsUploadPageState();
}

class _ShortsUploadPageState extends ConsumerState<ShortsUploadPage> {
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();
  String? _videoPath;
  String? _thumbPath;
  VideoPlayerController? _preview;
  var _picking = false;
  var _uploading = false;
  String? _error;
  double? _durationSec;

  @override
  void dispose() {
    _descCtrl.dispose();
    _preview?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 16),
      );
      if (file == null) return;

      final path = file.path;
      final bytes = await File(path).length();
      if (bytes > _maxBytes) {
        setState(() => _error = 'Video en fazla 10 MB olabilir.');
        return;
      }

      await _preview?.dispose();
      final controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      final dur = controller.value.duration.inMilliseconds / 1000.0;
      if (dur > _maxDurationSec + 0.25) {
        await controller.dispose();
        setState(() => _error = 'Video en fazla 15 saniye olabilir.');
        return;
      }

      final thumb = await VideoThumbnail.thumbnailFile(
        video: path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 80,
      );

      setState(() {
        _videoPath = path;
        _thumbPath = thumb;
        _preview = controller;
        _durationSec = dur;
      });
      controller.setLooping(true);
      await controller.play();
    } catch (e) {
      setState(() => _error = 'Video seçilemedi: $e');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _upload() async {
    final path = _videoPath;
    if (path == null) {
      setState(() => _error = 'Önce bir video seçin.');
      return;
    }
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || userId.isEmpty) {
      setState(() => _error = 'Yükleme için giriş yapmalısınız.');
      return;
    }

    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      await ref.read(shortsRepositoryProvider).uploadVideo(
            videoPath: path,
            thumbnailPath: _thumbPath,
            description: _descCtrl.text,
          );
      await ref.read(shortsFeedProvider.notifier).refresh();
      if (!mounted) return;
      context.pop();
      if (context.canPop()) {
        context.pop();
      } else {
        context.push('/shorts');
      }
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Yükleme başarısız: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E12),
      appBar: AppBar(
        title: const Text('Kısa Video Yükle'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 9 / 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: preview != null && preview.value.isInitialized
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: preview.value.size.width,
                              height: preview.value.size.height,
                              child: VideoPlayer(preview),
                            ),
                          ),
                          if (_durationSec != null)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_durationSec!.toStringAsFixed(1)} sn',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Center(
                        child: _picking
                            ? CircularProgressIndicator(
                                color: AppColors.accentPurple,
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.video_library_outlined,
                                    size: 48,
                                    color: Colors.white38,
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton.icon(
                                    onPressed: _pickVideo,
                                    icon: const Icon(Icons.photo_library_outlined),
                                    label: const Text('Galeriden seç'),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'MP4 · max 15 sn · max 10 MB · 9:16',
                                    style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                      ),
              ),
            ),
          ),
          if (_videoPath != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _picking ? null : _pickVideo,
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Başka video seç'),
            ),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _descCtrl,
            maxLength: 500,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Açıklama',
              labelStyle: const TextStyle(color: Colors.white54),
              hintText: 'Videon hakkında kısa bir not...',
              hintStyle: const TextStyle(color: Colors.white30),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _uploading || _videoPath == null ? null : _upload,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.accentPurple,
            ),
            child: _uploading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Yayınla'),
          ),
        ],
      ),
    );
  }
}
