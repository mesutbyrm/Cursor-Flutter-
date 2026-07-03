import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Dikey kısa video için yedek boyut (9:16).
const Size kDefaultPortraitVideoSize = Size(1080, 1920);

/// VideoPlayer bazen `Size.zero` / NaN döndürür — layout'ta `toInt` hatası üretir.
Size safeVideoPlayerSize(
  VideoPlayerValue value, {
  Size fallback = kDefaultPortraitVideoSize,
}) {
  final w = value.size.width;
  final h = value.size.height;
  if (w.isFinite && h.isFinite && w > 0 && h > 0) {
    return Size(w, h);
  }
  return fallback;
}

double safeVideoAspectRatio(
  VideoPlayerValue value, {
  double fallback = 9 / 16,
}) {
  final w = value.size.width;
  final h = value.size.height;
  if (w.isFinite && h.isFinite && w > 0 && h > 0) {
    final ratio = w / h;
    if (ratio.isFinite && ratio > 0) return ratio;
  }
  return fallback;
}

/// Tam ekran kaplama — geçersiz boyutlarda çökmez.
class SafeCoverVideoPlayer extends StatelessWidget {
  const SafeCoverVideoPlayer({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final size = safeVideoPlayerSize(controller.value);
          return FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(controller),
            ),
          );
        },
      ),
    );
  }
}
