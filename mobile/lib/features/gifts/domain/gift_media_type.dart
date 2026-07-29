import 'gift_animation_kind.dart';
import 'gift_asset_type.dart';
import 'gift_engine_models.dart';

/// Backend `mediaType` / `assetType` / `assetFormat` → oynatıcı dalı.
enum GiftMediaType {
  video,
  png,
  webp,
  svg,
  gif,
  lottie,
  unknown;

  bool get isVideo => this == GiftMediaType.video;

  bool get isRasterImage =>
      this == GiftMediaType.png || this == GiftMediaType.webp;

  static GiftMediaType resolve({
    String? mediaType,
    String? assetType,
    String? assetFormat,
    String? animationType,
    String? url,
    GiftAssetType? catalogAssetType,
    GiftAnimationKind? animationKind,
  }) {
    for (final raw in [
      mediaType,
      assetType,
      assetFormat,
      animationType,
    ]) {
      final parsed = _fromRaw(raw);
      if (parsed != GiftMediaType.unknown) return parsed;
    }
    if (catalogAssetType == GiftAssetType.video) return GiftMediaType.video;
    if (animationKind == GiftAnimationKind.video) return GiftMediaType.video;
    if (animationKind == GiftAnimationKind.gif) return GiftMediaType.gif;
    if (animationKind == GiftAnimationKind.image) return GiftMediaType.png;

    final inferred = GiftEngineAnimationType.inferFromUrl(url);
    return switch (inferred) {
      GiftEngineAnimationType.mp4 || GiftEngineAnimationType.webm =>
        GiftMediaType.video,
      GiftEngineAnimationType.svg => GiftMediaType.svg,
      GiftEngineAnimationType.gif => GiftMediaType.gif,
      GiftEngineAnimationType.lottie => GiftMediaType.lottie,
      GiftEngineAnimationType.png => GiftMediaType.png,
      _ => _fromUrl(url),
    };
  }

  static GiftMediaType _fromRaw(String? raw) {
    if (raw == null || raw.trim().isEmpty) return GiftMediaType.unknown;
    return switch (raw.toLowerCase().trim()) {
      'video' || 'mp4' || 'webm' => GiftMediaType.video,
      'svg' => GiftMediaType.svg,
      'gif' => GiftMediaType.gif,
      'webp' => GiftMediaType.webp,
      'png' || 'image' || 'jpg' || 'jpeg' || 'avif' => GiftMediaType.png,
      'lottie' || 'json' => GiftMediaType.lottie,
      _ => GiftMediaType.unknown,
    };
  }

  static GiftMediaType _fromUrl(String? url) {
    if (url == null || url.trim().isEmpty) return GiftMediaType.unknown;
    final lower = url.toLowerCase().split('?').first;
    if (lower.endsWith('.mp4') || lower.endsWith('.webm')) {
      return GiftMediaType.video;
    }
    if (lower.endsWith('.svg')) return GiftMediaType.svg;
    if (lower.endsWith('.gif')) return GiftMediaType.gif;
    if (lower.endsWith('.webp') || lower.endsWith('.avif')) {
      return GiftMediaType.webp;
    }
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg')) {
      return GiftMediaType.png;
    }
    if (lower.endsWith('.json')) return GiftMediaType.lottie;
    return GiftMediaType.unknown;
  }
}
