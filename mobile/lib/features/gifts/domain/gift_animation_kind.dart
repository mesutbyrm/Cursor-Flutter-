enum GiftAnimationKind {
  none,
  lottie,
  rive,
  svga,
  video,
  gif,
  image;

  static GiftAnimationKind parse(String? raw) {
    return switch (raw?.toLowerCase().trim()) {
      'rive' => GiftAnimationKind.rive,
      'svga' => GiftAnimationKind.svga,
      'lottie' => GiftAnimationKind.lottie,
      'mp4' => GiftAnimationKind.video,
      'webm' => GiftAnimationKind.video,
      'video' => GiftAnimationKind.video,
      'gif' => GiftAnimationKind.gif,
      'image' => GiftAnimationKind.image,
      'png' => GiftAnimationKind.image,
      'webp' => GiftAnimationKind.image,
      'avif' => GiftAnimationKind.image,
      'none' => GiftAnimationKind.none,
      _ => GiftAnimationKind.none,
    };
  }

  static GiftAnimationKind fromUrl(String? url) {
    if (url == null || url.isEmpty) return GiftAnimationKind.none;
    final lower = url.toLowerCase().split('?').first;
    if (lower.endsWith('.mp4') || lower.endsWith('.webm')) {
      return GiftAnimationKind.video;
    }
    if (lower.endsWith('.gif')) return GiftAnimationKind.gif;
    if (lower.endsWith('.json')) return GiftAnimationKind.lottie;
    if (lower.endsWith('.svga')) return GiftAnimationKind.svga;
    if (lower.endsWith('.riv')) return GiftAnimationKind.rive;
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.avif')) {
      return GiftAnimationKind.image;
    }
    return GiftAnimationKind.none;
  }
}
