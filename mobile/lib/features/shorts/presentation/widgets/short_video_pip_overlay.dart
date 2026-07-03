import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/video/safe_video_layout.dart';
import '../../domain/entities/short_video_entity.dart';

class ShortVideoPipState {
  const ShortVideoPipState({
    this.video,
    this.controller,
    this.position = Offset.zero,
  });

  final ShortVideoEntity? video;
  final VideoPlayerController? controller;
  final Offset position;

  bool get active => video != null && controller != null;

  ShortVideoPipState copyWith({
    ShortVideoEntity? video,
    VideoPlayerController? controller,
    Offset? position,
    bool clear = false,
  }) {
    if (clear) {
      return const ShortVideoPipState();
    }
    return ShortVideoPipState(
      video: video ?? this.video,
      controller: controller ?? this.controller,
      position: position ?? this.position,
    );
  }
}

class ShortVideoPipNotifier extends Notifier<ShortVideoPipState> {
  @override
  ShortVideoPipState build() => const ShortVideoPipState();

  void activate({
    required ShortVideoEntity video,
    required VideoPlayerController controller,
  }) {
    state.controller?.pause();
    state = ShortVideoPipState(
      video: video,
      controller: controller,
      position: const Offset(16, 80),
    );
    controller.play();
  }

  void move(Offset delta) {
    if (!state.active) return;
    state = state.copyWith(position: state.position + delta);
  }

  Future<void> close() async {
    final c = state.controller;
    state = const ShortVideoPipState();
    await c?.pause();
  }

  void expand() {
    state = const ShortVideoPipState();
  }
}

final shortVideoPipProvider =
    NotifierProvider<ShortVideoPipNotifier, ShortVideoPipState>(
  ShortVideoPipNotifier.new,
);

/// Picture-in-Picture benzeri sürüklenebilir mini oynatıcı.
class ShortVideoPipOverlay extends ConsumerWidget {
  const ShortVideoPipOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pip = ref.watch(shortVideoPipProvider);
    if (!pip.active) return const SizedBox.shrink();

    final c = pip.controller!;
    final size = MediaQuery.sizeOf(context);

    return Positioned(
      left: pip.position.dx.clamp(8, size.width - 128),
      top: pip.position.dy.clamp(48, size.height - 240),
      child: GestureDetector(
        onPanUpdate: (d) {
          ref.read(shortVideoPipProvider.notifier).move(d.delta);
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: 112,
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (c.value.isInitialized)
                  SafeCoverVideoPlayer(controller: c)
                else
                  const ColoredBox(color: Colors.black),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PipIcon(
                        icon: Icons.close,
                        onTap: () =>
                            ref.read(shortVideoPipProvider.notifier).close(),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  right: 4,
                  child: Text(
                    pip.video!.author?.username ?? 'Kısa video',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PipIcon extends StatelessWidget {
  const _PipIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}
