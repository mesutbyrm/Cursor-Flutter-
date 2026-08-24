/// Görsel efekt türü — backend `render.type` veya yerleşik katalog.
enum CosmeticEffectKind {
  // Çerçeve
  rotatingLight,
  neonGlow,
  fire,
  goldParticles,
  diamond,
  cosmicStars,
  aura,
  heart,
  lightning,
  rainbow,
  crown,
  imageOverlay,
  // İsim
  goldText,
  silverText,
  diamondText,
  neonText,
  rainbowText,
  glowText,
  fireText,
  crystalText,
  glassText,
  hologramText,
  // Parçacık (profil)
  particleStars,
  particleSnow,
  particleRoses,
  particleHearts,
  particleButterflies,
  particleMoon,
  particleSmoke,
  particleGalaxy,
  particleGoldDust,
  particleDiamonds,
  // Giriş
  entranceDragon,
  entranceGoldRain,
  entranceMeteor,
  entranceWings,
  entranceAngel,
  entranceFireworks,
  entranceCrown,
  entranceGalaxy,
  plain,
}

extension CosmeticEffectKindX on CosmeticEffectKind {
  static CosmeticEffectKind? parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final k = raw.trim().toLowerCase().replaceAll('-', '_');
    for (final v in CosmeticEffectKind.values) {
      if (v.name.toLowerCase() == k) return v;
    }
    return switch (k) {
      'rotating_light' || 'spin_light' => CosmeticEffectKind.rotatingLight,
      'neon' || 'neon_glow' => CosmeticEffectKind.neonGlow,
      'gold' || 'gold_frame' => CosmeticEffectKind.goldParticles,
      'cosmic' || 'stars' => CosmeticEffectKind.cosmicStars,
      'gold_text' => CosmeticEffectKind.goldText,
      'rainbow_text' => CosmeticEffectKind.rainbowText,
      _ => null,
    };
  }

  bool get isFrame => index <= CosmeticEffectKind.imageOverlay.index;
  bool get isName => index >= CosmeticEffectKind.goldText.index &&
      index <= CosmeticEffectKind.hologramText.index;
  bool get isParticle => index >= CosmeticEffectKind.particleStars.index &&
      index <= CosmeticEffectKind.particleDiamonds.index;
}
