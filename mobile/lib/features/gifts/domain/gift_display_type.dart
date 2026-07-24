import '../../../core/util/enum_from.dart';

/// Backend `GiftType.displayType` — hediye sistemi dokümanı §2.1.
enum GiftDisplayType {
  standard,
  fullscreen,
  banner,
  combo,
  static_,
  animation,
  video,
  lottie,
  effect,
  mini,
  continuous,
  playOnce,
  unknown;

  static GiftDisplayType parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return GiftDisplayType.standard;
    final normalized = raw.trim().toLowerCase().replaceAll('-', '_');
    return switch (normalized) {
      'static' => GiftDisplayType.static_,
      'animation' => GiftDisplayType.animation,
      'video' => GiftDisplayType.video,
      'lottie' => GiftDisplayType.lottie,
      'effect' => GiftDisplayType.effect,
      'fullscreen' => GiftDisplayType.fullscreen,
      'mini' => GiftDisplayType.mini,
      'continuous' => GiftDisplayType.continuous,
      'play_once' => GiftDisplayType.playOnce,
      'banner' => GiftDisplayType.banner,
      'combo' => GiftDisplayType.combo,
      'standard' => GiftDisplayType.standard,
      _ => enumFrom(GiftDisplayType.values, normalized, GiftDisplayType.unknown),
    };
  }

  bool get isFullscreenLayer =>
      this == GiftDisplayType.fullscreen || this == GiftDisplayType.effect;
}
