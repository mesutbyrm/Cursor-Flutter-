/// Canlı keşfet kategori filtresi — TikTok Live benzeri.
enum LiveDiscoverCategory {
  all,
  fortune,
  tarot,
  coffee,
  katina,
  dream,
  numerology,
  astrology,
  palm,
  aura,
  angel,
  love,
  chat,
  music,
  talk,
  game,
  general,
}

extension LiveDiscoverCategoryX on LiveDiscoverCategory {
  String get label => switch (this) {
        LiveDiscoverCategory.all => 'Tümü',
        LiveDiscoverCategory.fortune => 'Fal',
        LiveDiscoverCategory.tarot => 'Tarot',
        LiveDiscoverCategory.coffee => 'Kahve',
        LiveDiscoverCategory.katina => 'Katina',
        LiveDiscoverCategory.dream => 'Rüya',
        LiveDiscoverCategory.numerology => 'Numeroloji',
        LiveDiscoverCategory.astrology => 'Astroloji',
        LiveDiscoverCategory.palm => 'El Falı',
        LiveDiscoverCategory.aura => 'Aura',
        LiveDiscoverCategory.angel => 'Melek',
        LiveDiscoverCategory.love => 'Aşk',
        LiveDiscoverCategory.chat => 'Sohbet',
        LiveDiscoverCategory.music => 'Müzik',
        LiveDiscoverCategory.talk => 'Muhabbet',
        LiveDiscoverCategory.game => 'Oyun',
        LiveDiscoverCategory.general => 'Genel',
      };

  String? get apiCategory => switch (this) {
        LiveDiscoverCategory.all => null,
        LiveDiscoverCategory.fortune ||
        LiveDiscoverCategory.tarot ||
        LiveDiscoverCategory.coffee ||
        LiveDiscoverCategory.katina ||
        LiveDiscoverCategory.dream ||
        LiveDiscoverCategory.numerology ||
        LiveDiscoverCategory.astrology ||
        LiveDiscoverCategory.palm ||
        LiveDiscoverCategory.aura ||
        LiveDiscoverCategory.angel ||
        LiveDiscoverCategory.love =>
          'fortune',
        LiveDiscoverCategory.chat ||
        LiveDiscoverCategory.music ||
        LiveDiscoverCategory.talk =>
          'chat',
        LiveDiscoverCategory.game || LiveDiscoverCategory.general => 'general',
      };

  List<String> get keywords => switch (this) {
        LiveDiscoverCategory.all => const [],
        LiveDiscoverCategory.fortune => const ['fal', 'fortune'],
        LiveDiscoverCategory.tarot => const ['tarot'],
        LiveDiscoverCategory.coffee => const ['kahve', 'coffee'],
        LiveDiscoverCategory.katina => const ['katina'],
        LiveDiscoverCategory.dream => const ['rüya', 'ruya', 'dream'],
        LiveDiscoverCategory.numerology => const ['numeroloji', 'numerology'],
        LiveDiscoverCategory.astrology => const ['astro', 'yıldız', 'yildiz'],
        LiveDiscoverCategory.palm => const ['el fal', 'palm'],
        LiveDiscoverCategory.aura => const ['aura'],
        LiveDiscoverCategory.angel => const ['melek', 'angel'],
        LiveDiscoverCategory.love => const ['aşk', 'ask', 'love'],
        LiveDiscoverCategory.chat => const ['sohbet', 'chat'],
        LiveDiscoverCategory.music => const ['müzik', 'muzik', 'music'],
        LiveDiscoverCategory.talk => const ['muhabbet', 'talk'],
        LiveDiscoverCategory.game => const ['oyun', 'game'],
        LiveDiscoverCategory.general => const ['genel', 'general'],
      };

  bool get isFortuneFamily => switch (this) {
        LiveDiscoverCategory.fortune ||
        LiveDiscoverCategory.tarot ||
        LiveDiscoverCategory.coffee ||
        LiveDiscoverCategory.katina ||
        LiveDiscoverCategory.dream ||
        LiveDiscoverCategory.numerology ||
        LiveDiscoverCategory.astrology ||
        LiveDiscoverCategory.palm ||
        LiveDiscoverCategory.aura ||
        LiveDiscoverCategory.angel ||
        LiveDiscoverCategory.love =>
          true,
        _ => false,
      };
}

const liveDiscoverChipCategories = [
  LiveDiscoverCategory.all,
  LiveDiscoverCategory.fortune,
  LiveDiscoverCategory.tarot,
  LiveDiscoverCategory.coffee,
  LiveDiscoverCategory.love,
  LiveDiscoverCategory.music,
  LiveDiscoverCategory.chat,
  LiveDiscoverCategory.game,
];
