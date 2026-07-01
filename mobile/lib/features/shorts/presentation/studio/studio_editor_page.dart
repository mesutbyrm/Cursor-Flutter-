import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/short_upload_draft.dart';
import '../utils/shorts_api_message.dart';
import 'short_studio_providers.dart';
import 'studio_video_export.dart';

/// Kırpma, döndürme, filtre, hız, kapak — video_editor + FFmpeg.
class StudioEditorPage extends ConsumerStatefulWidget {
  const StudioEditorPage({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<StudioEditorPage> createState() => _StudioEditorPageState();
}

class _StudioEditorPageState extends ConsumerState<StudioEditorPage> {
  VideoEditorController? _controller;
  var _exporting = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initController(String path) async {
    if (_controller != null) return;
    final c = VideoEditorController.file(
      File(path),
      minDuration: const Duration(seconds: 1),
      maxDuration: const Duration(seconds: 15),
    );
    await c.initialize();
    if (!mounted) {
      c.dispose();
      return;
    }
    setState(() => _controller = c);
  }

  ColorFilter _colorFilter(ShortUploadDraft draft) {
    final b = draft.brightness.clamp(-0.5, 0.5);
    final c = draft.contrast.clamp(0.5, 2.0);
    final s = draft.saturation.clamp(0, 2.0);
    return ColorFilter.matrix([
      c * s, 0, 0, 0, b * 255,
      0, c * s, 0, 0, b * 255,
      0, 0, c * s, 0, b * 255,
      0, 0, 0, 1, 0,
    ]);
  }

  Future<void> _exportAndContinue() async {
    final c = _controller;
    if (c == null || _exporting) return;
    setState(() => _exporting = true);
    try {
      final draft = ref.read(shortUploadDraftProvider);
      final outPath = await exportEditedShortVideo(
        c,
        playbackSpeed: draft.playbackSpeed,
      );
      final ms = coverTimeMs(c);
      final thumb = await VideoThumbnail.thumbnailFile(
        video: outPath,
        imageFormat: ImageFormat.JPEG,
        timeMs: ms,
        maxWidth: 720,
        quality: 85,
      );

      ref.read(shortUploadDraftProvider.notifier).patch(
            (d) => d.copyWith(
              editedPath: outPath,
              thumbnailPath: thumb,
              coverTimeMs: ms,
            ),
          );
      widget.onNext();
    } catch (e) {
      if (mounted) showShortsSnackBar(context, 'Dışa aktarma başarısız: $e');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(shortUploadDraftProvider);
    final path = draft.sourcePath!;
    _initController(path);
    final c = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onBack,
        ),
        title: const Text('Düzenle'),
        actions: [
          IconButton(
            tooltip: 'Döndür',
            onPressed: c == null ? null : () => c.rotate90Degrees(),
            icon: const Icon(Icons.rotate_90_degrees_ccw_outlined),
          ),
          TextButton(
            onPressed: _exporting ? null : _exportAndContinue,
            child: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('İleri', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: c == null || !c.initialized
          ? Center(child: CircularProgressIndicator(color: AppColors.accentPurple))
          : Column(
              children: [
                Expanded(
                  child: ColorFiltered(
                    colorFilter: _colorFilter(draft),
                    child: CropGridViewer.preview(controller: c),
                  ),
                ),
                TrimSlider(controller: c, height: 48, horizontalMargin: 12),
                CoverSelection(controller: c, size: 56),
                _AdjustPanel(
                  draft: draft,
                  onChanged: (d) =>
                      ref.read(shortUploadDraftProvider.notifier).patch((_) => d),
                ),
              ],
            ),
    );
  }
}

class _AdjustPanel extends StatelessWidget {
  const _AdjustPanel({required this.draft, required this.onChanged});

  final ShortUploadDraft draft;
  final ValueChanged<ShortUploadDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Column(
        children: [
          Row(
            children: [
              _SpeedChip(
                label: '0.5x',
                selected: draft.playbackSpeed == 0.5,
                onTap: () => onChanged(draft.copyWith(playbackSpeed: 0.5)),
              ),
              _SpeedChip(
                label: '1x',
                selected: draft.playbackSpeed == 1,
                onTap: () => onChanged(draft.copyWith(playbackSpeed: 1)),
              ),
              _SpeedChip(
                label: '1.5x',
                selected: draft.playbackSpeed == 1.5,
                onTap: () => onChanged(draft.copyWith(playbackSpeed: 1.5)),
              ),
              _SpeedChip(
                label: '2x',
                selected: draft.playbackSpeed == 2,
                onTap: () => onChanged(draft.copyWith(playbackSpeed: 2)),
              ),
              const Spacer(),
              FilterChip(
                label: const Text('Sessiz'),
                selected: draft.muted,
                onSelected: (v) => onChanged(draft.copyWith(muted: v)),
              ),
            ],
          ),
          _SliderRow(
            label: 'Parlaklık',
            value: draft.brightness,
            min: -0.5,
            max: 0.5,
            onChanged: (v) => onChanged(draft.copyWith(brightness: v)),
          ),
          _SliderRow(
            label: 'Kontrast',
            value: draft.contrast,
            min: 0.5,
            max: 2,
            onChanged: (v) => onChanged(draft.copyWith(contrast: v)),
          ),
          _SliderRow(
            label: 'Doygunluk',
            value: draft.saturation,
            min: 0,
            max: 2,
            onChanged: (v) => onChanged(draft.copyWith(saturation: v)),
          ),
        ],
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
