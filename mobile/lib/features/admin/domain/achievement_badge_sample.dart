/// Başarı / görev rozeti örnekleri — admin rozet yönetimi.
class AchievementBadgeSample {
  const AchievementBadgeSample({
    required this.id,
    required this.name,
    required this.description,
    this.iconEmoji = '🏅',
    this.tier = 'common',
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String description;
  final String iconEmoji;
  final String tier;
  final int sortOrder;
}

abstract final class AchievementBadgeSampleCatalog {
  static const _defs = <(String, String, String, String)>[
    ('badge_first_gift', 'İlk Hediye', 'İlk hediyeni gönder', '🎁'),
    ('badge_gift_100', 'Cömert', '100 hediye gönder', '💝'),
    ('badge_gift_1000', 'El Uzatan', '1000 hediye gönder', '🌟'),
    ('badge_room_host', 'Oda Kurucusu', 'İlk odanı aç', '🎙️'),
    ('badge_stream_1h', 'Yayıncı', '1 saat canlı yayın', '📺'),
    ('badge_pk_win', 'PK Şampiyonu', 'PK galibiyeti', '⚔️'),
    ('badge_fortune', 'Falcı Dostu', 'Canlı fal seansı tamamla', '🔮'),
    ('badge_social', 'Sosyal Kelebek', '50 takipçi', '🦋'),
    ('badge_vip', 'VIP Üye', 'Gold üyelik', '👑'),
    ('badge_diamond', 'Elmas Üye', 'Diamond üyelik', '💎'),
    ('badge_streak_7', '7 Gün Seri', '7 gün üst üste giriş', '🔥'),
    ('badge_streak_30', '30 Gün Seri', '30 gün üst üste giriş', '💫'),
    ('badge_music_dj', 'DJ', '50 şarkı isteği', '🎵'),
    ('badge_lucky', 'Şanslı', 'Jackpot kazan', '🍀'),
    ('badge_supporter', 'Destekçi', 'Yayıncıya 10K jeton hediye', '🤝'),
    ('badge_moderator', 'Moderatör', 'Moderasyon rozeti', '🛡️'),
    ('badge_founder', 'Kurucu', 'Kurucu rozeti', '🏛️'),
    ('badge_event', 'Etkinlik', 'Özel etkinlik katılımı', '🎉'),
    ('badge_collector', 'Koleksiyoncu', '20 farklı hediye topla', '📦'),
    ('badge_legend', 'Efsane', 'Tüm rozetleri topla', '🏆'),
  ];

  static final List<AchievementBadgeSample> samples = List.generate(
    _defs.length,
    (i) {
      final (id, name, desc, emoji) = _defs[i];
      return AchievementBadgeSample(
        id: id,
        name: name,
        description: desc,
        iconEmoji: emoji,
        tier: i >= 15 ? 'legendary' : i >= 8 ? 'epic' : 'common',
        sortOrder: i + 1,
      );
    },
  );
}
