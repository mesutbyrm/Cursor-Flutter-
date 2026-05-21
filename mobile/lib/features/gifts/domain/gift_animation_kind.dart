enum GiftAnimationKind {
  none,
  lottie,
  rive,
  svga;

  static GiftAnimationKind parse(String? raw) {
    return switch (raw?.toLowerCase().trim()) {
      'rive' => GiftAnimationKind.rive,
      'svga' => GiftAnimationKind.svga,
      'lottie' => GiftAnimationKind.lottie,
      'none' => GiftAnimationKind.none,
      _ => GiftAnimationKind.lottie,
    };
  }
}
