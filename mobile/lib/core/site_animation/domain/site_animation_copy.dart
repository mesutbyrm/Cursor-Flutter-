import '../domain/site_animation_tier.dart';
import '../domain/site_animation_type.dart';

/// Tasarım referanslarına uygun Türkçe overlay metinleri.
abstract final class SiteAnimationCopy {
  static String subtitle({
    required String userName,
    required SiteAnimationType type,
    required SiteAnimationTier tier,
  }) {
    final name = userName.trim().isEmpty ? 'Kullanıcı' : userName.trim();
    return switch (type) {
      SiteAnimationType.memberJoined => _entrance(name, tier),
      SiteAnimationType.hostSeat => _hostEntrance(name),
      SiteAnimationType.memberLeft => _exit(name, tier),
      SiteAnimationType.seatChanged => '$name koltuk değiştirdi',
      SiteAnimationType.micEnabled => '$name mikrofonu açtı',
      SiteAnimationType.micDisabled => '$name mikrofonu kapattı',
      SiteAnimationType.seatRankGlow => _seatGlow(name, tier),
    };
  }

  static String _entrance(String name, SiteAnimationTier tier) {
    if (tier == SiteAnimationTier.normal) {
      return '$name odaya katıldı';
    }
    return '$name — ${_tierLabel(tier)} üye odaya katıldı';
  }

  static String _hostEntrance(String name) =>
      '$name — Host koltuğuna geçti';

  static String _exit(String name, SiteAnimationTier tier) => switch (tier) {
        SiteAnimationTier.normal => '$name — Güle güle',
        SiteAnimationTier.gold => '$name — Tekrar bekleriz',
        SiteAnimationTier.premium => '$name — Yine bekleriz',
        SiteAnimationTier.diamond => '$name — Işıkla kal',
        SiteAnimationTier.vip => '$name — Kral geri dönecek',
        SiteAnimationTier.svip => '$name — İmparator yakında dönecek',
        SiteAnimationTier.admin => '$name — Sistemden ayrıldı',
        SiteAnimationTier.host => '$name — Host odadan ayrıldı',
      };

  static String _seatGlow(String name, SiteAnimationTier tier) => switch (tier) {
        SiteAnimationTier.gold => '$name — Altın koltuk parlıyor',
        SiteAnimationTier.premium => '$name — Premium koltuk aktif',
        SiteAnimationTier.diamond => '$name — Kristal koltuk parlıyor',
        SiteAnimationTier.vip => '$name — VIP kanat efekti',
        SiteAnimationTier.svip => '$name — Kraliyet koltuğu',
        SiteAnimationTier.admin => '$name — Admin taç efekti',
        SiteAnimationTier.host => '$name — Host taç efekti',
        SiteAnimationTier.normal => '$name — Koltuk efekti aktif',
      };

  static String _tierLabel(SiteAnimationTier tier) => switch (tier) {
        SiteAnimationTier.normal => 'Normal',
        SiteAnimationTier.gold => 'Gold',
        SiteAnimationTier.premium => 'Premium',
        SiteAnimationTier.diamond => 'Diamond',
        SiteAnimationTier.vip => 'VIP',
        SiteAnimationTier.svip => 'SVIP',
        SiteAnimationTier.admin => 'Admin',
        SiteAnimationTier.host => 'Host',
      };
}
