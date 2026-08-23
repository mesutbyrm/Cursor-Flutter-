import 'dart:io';
import 'dart:math' as math;

import 'package:canlifal_social/core/performance/list_perf.dart';
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
  String? _selectedStickerId;

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
    setState(() {
      _selectedTextId = id;
      _selectedStickerId = null;
    });
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
    setState(() {
      _selectedStickerId = id;
      _selectedTextId = null;
    });
  }

  void _removeSelected() {
    final textId = _selectedTextId;
    final stickerId = _selectedStickerId;
    if (textId == null && stickerId == null) return;
    ref.read(shortUploadDraftProvider.notifier).patch((d) {
      return d.copyWith(
        textOverlays: [
          for (final o in d.textOverlays)
            if (o.id != textId) o,
        ],
        stickerOverlays: [
          for (final o in d.stickerOverlays)
            if (o.id != stickerId) o,
        ],
      );
    });
    setState(() {
      _selectedTextId = null;
      _selectedStickerId = null;
    });
  }

  Future<void> _editSelectedText() async {
    final textId = _selectedTextId;
    if (textId == null) return;
    ShortTextOverlay? current;
    for (final overlay in ref.read(shortUploadDraftProvider).textOverlays) {
      if (overlay.id == textId) {
        current = overlay;
        break;
      }
    }
    if (current == null) return;
    final controller = TextEditingController(text: current.text);
    final edited = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yazıyı düzenle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (edited == null || edited.isEmpty) return;
    ref.read(shortUploadDraftProvider.notifier).patch((d) {
      return d.copyWith(
        textOverlays: [
          for (final o in d.textOverlays)
            o.id == textId ? o.copyWith(text: edited) : o,
        ],
      );
    });
  }

  Future<void> _openEmojiPicker() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF121218),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => const _EmojiPickerSheet(),
    );
    if (picked != null && picked.isNotEmpty) _addEmoji(picked);
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
                    onSelect: () => setState(() {
                      _selectedTextId = t.id;
                      _selectedStickerId = null;
                    }),
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
                    selected: _selectedStickerId == s.id,
                    onSelect: () => setState(() {
                      _selectedStickerId = s.id;
                      _selectedTextId = null;
                    }),
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
          if (_selectedTextId != null || _selectedStickerId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  if (_selectedTextId != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _editSelectedText,
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Yazıyı düzenle'),
                      ),
                    ),
                  if (_selectedTextId != null) const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _removeSelected,
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Seçileni sil'),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ActionChip(
                  avatar: const Icon(Icons.emoji_emotions_outlined, size: 18),
                  label: const Text('Tüm emojiler'),
                  onPressed: _openEmojiPicker,
                ),
                for (final e in _quickEmojis)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ActionChip(
                      label: Text(e, style: const TextStyle(fontSize: 22)),
                      onPressed: () => _addEmoji(e),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

const _quickEmojis = ['😀', '🔥', '❤️', '✨', '🎵', '👏', '💯', '🌙'];

const _allEmojiGroups = <String, List<String>>{
  'Popüler': ['😀', '😂', '😍', '🥰', '😎', '😭', '😡', '🤯', '🥳', '😇', '🙌', '🙏'],
  'Kalpler': ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '💖', '💘', '💝', '💔'],
  'Etkiler': ['🔥', '✨', '⭐', '🌟', '💫', '⚡', '💥', '🌈', '☀️', '🌙', '🪐', '🔮'],
  'Sosyal': ['👏', '💯', '🎉', '🎁', '🏆', '👑', '💎', '🎵', '🎤', '📸', '🎬', '🚀'],
  'CanlıFal': ['☕', '🃏', '🧿', '🕯️', '🌹', '🦋', '🐬', '🍀', '🪬', '🧚', '🪽', '💰'],
};

class _EmojiPickerSheet extends StatelessWidget {
  const _EmojiPickerSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          const Text(
            'Emoji / Sticker seç',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in _allEmojiGroups.entries) ...[
            Text(
              entry.key,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                const crossAxisCount = 6;
                const spacing = 8.0;
                final gridHeight = ListPerf.nestedGridHeight(
                  itemCount: entry.value.length,
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: 1,
                  crossAxisExtent: MediaQuery.sizeOf(context).width - 32,
                );
                return SizedBox(
                  height: gridHeight,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                    ),
                    itemCount: entry.value.length,
                    itemBuilder: (context, index) {
                      final emoji = entry.value[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.pop(context, emoji),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Center(
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
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
                  : const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: overlay.backgroundColor ??
                    (selected ? Colors.black.withValues(alpha: 0.18) : null),
                borderRadius: BorderRadius.circular(6),
                border: selected
                    ? Border.all(color: Colors.white, width: 1.5)
                    : null,
              ),
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
  const _DraggableSticker({
    required this.sticker,
    required this.selected,
    required this.onSelect,
    required this.onMove,
  });

  final ShortStickerOverlay sticker;
  final bool selected;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onMove;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: sticker.position.dx,
      top: sticker.position.dy,
      child: GestureDetector(
        onTap: onSelect,
        onPanUpdate: (d) => onMove(sticker.position + d.delta),
        child: Container(
          padding: selected ? const EdgeInsets.all(4) : EdgeInsets.zero,
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                  color: Colors.black.withValues(alpha: 0.18),
                )
              : null,
          child: Transform.rotate(
            angle: sticker.rotation * math.pi / 180,
            child: Text(
              sticker.emoji,
              style: TextStyle(fontSize: 42 * sticker.scale),
            ),
          ),
        ),
      ),
    );
  }
}
