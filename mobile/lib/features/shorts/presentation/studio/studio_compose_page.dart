import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';

import '../../domain/entities/short_upload_draft.dart';
import 'short_studio_providers.dart';

/// Videonun üzerine sürüklenebilir yazı ve emoji sticker.
class StudioComposePage extends ConsumerStatefulWidget {
  const StudioComposePage({
    super.key,
    required this.onNext,
    required this.onBack,
  });

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  ConsumerState<StudioComposePage> createState() => _StudioComposePageState();
}

class _StudioComposePageState extends ConsumerState<StudioComposePage> {
  VideoPlayerController? _player;
  final _textCtrl = TextEditingController();
  String? _selectedTextId;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final path = ref.read(shortUploadDraftProvider).videoPath;
    if (path == null) return;
    final c = VideoPlayerController.file(File(path));
    await c.initialize();
    c.setLooping(true);
    await c.play();
    if (mounted) setState(() => _player = c);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _player?.dispose();
    super.dispose();
  }

  void _addText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    final id = const Uuid().v4();
    ref.read(shortUploadDraftProvider.notifier).patch((d) {
      return d.copyWith(
        textOverlays: [
          ...d.textOverlays,
          ShortTextOverlay(
            id: id,
            text: text,
            position: const Offset(40, 120),
          ),
        ],
      );
    });
    _textCtrl.clear();
    setState(() => _selectedTextId = id);
  }

  void _addEmoji(String emoji) {
    final id = const Uuid().v4();
    ref.read(shortUploadDraftProvider.notifier).patch((d) {
      return d.copyWith(
        stickerOverlays: [
          ...d.stickerOverlays,
          ShortStickerOverlay(
            id: id,
            emoji: emoji,
            position: Offset(80 + d.stickerOverlays.length * 12.0, 200),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(shortUploadDraftProvider);
    final player = _player;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
        ),
        title: const Text('Yazı & Sticker'),
        actions: [
          TextButton(
            onPressed: widget.onNext,
            child: const Text('İleri', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (player != null && player.value.isInitialized)
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: player.value.size.width,
                      height: player.value.size.height,
                      child: VideoPlayer(player),
                    ),
                  )
                else
                  const Center(child: CircularProgressIndicator()),
                for (final t in draft.textOverlays)
                  _DraggableTextOverlay(
                    overlay: t,
                    selected: _selectedTextId == t.id,
                    onSelect: () => setState(() => _selectedTextId = t.id),
                    onMove: (pos) {
                      ref.read(shortUploadDraftProvider.notifier).patch((d) {
                        return d.copyWith(
                          textOverlays: [
                            for (final o in d.textOverlays)
                              o.id == t.id ? o.copyWith(position: pos) : o,
                          ],
                        );
                      });
                    },
                  ),
                for (final s in draft.stickerOverlays)
                  _DraggableSticker(
                    sticker: s,
                    onMove: (pos) {
                      ref.read(shortUploadDraftProvider.notifier).patch((d) {
                        return d.copyWith(
                          stickerOverlays: [
                            for (final o in d.stickerOverlays)
                              o.id == s.id ? o.copyWith(position: pos) : o,
                          ],
                        );
                      });
                    },
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Yazı ekle...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _addText(),
                  ),
                ),
                IconButton(
                  onPressed: _addText,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['😀', '🔥', '❤️', '✨', '🎵', '👏', '💯', '🌙']
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(e, style: const TextStyle(fontSize: 22)),
                        onPressed: () => _addEmoji(e),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DraggableTextOverlay extends StatelessWidget {
  const _DraggableTextOverlay({
    required this.overlay,
    required this.selected,
    required this.onSelect,
    required this.onMove,
  });

  final ShortTextOverlay overlay;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onMove;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: overlay.position.dx,
      top: overlay.position.dy,
      child: GestureDetector(
        onTap: onSelect,
        onPanUpdate: (d) => onMove(overlay.position + d.delta),
        child: Transform.rotate(
          angle: overlay.rotation * math.pi / 180,
          child: Transform.scale(
            scale: overlay.scale,
            child: Container(
              padding: overlay.backgroundColor != null
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : null,
              decoration: overlay.backgroundColor != null
                  ? BoxDecoration(
                      color: overlay.backgroundColor,
                      borderRadius: BorderRadius.circular(6),
                    )
                  : null,
              child: Text(
                overlay.text,
                style: TextStyle(
                  color: overlay.color,
                  fontSize: overlay.fontSize,
                  fontWeight: FontWeight.w800,
                  shadows: overlay.hasShadow
                      ? const [Shadow(color: Colors.black54, blurRadius: 6)]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DraggableSticker extends StatelessWidget {
  const _DraggableSticker({required this.sticker, required this.onMove});

  final ShortStickerOverlay sticker;
  final ValueChanged<Offset> onMove;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: sticker.position.dx,
      top: sticker.position.dy,
      child: GestureDetector(
        onPanUpdate: (d) => onMove(sticker.position + d.delta),
        child: Transform.rotate(
          angle: sticker.rotation * math.pi / 180,
          child: Text(
            sticker.emoji,
            style: TextStyle(fontSize: 42 * sticker.scale),
          ),
        ),
      ),
    );
  }
}
