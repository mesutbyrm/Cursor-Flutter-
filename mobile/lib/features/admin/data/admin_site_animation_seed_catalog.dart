import 'admin_site_animation.dart';

/// Tasarım referanslarından seed katalog — API yoksa admin önizleme için.
abstract final class AdminSiteAnimationSeedCatalog {
  static List<AdminSiteAnimation> all() => [
        ..._entrance(),
        ..._exit(),
        ..._transition(),
        ..._seat(),
        ..._roomWide(),
        ..._mic(),
        ..._host(),
      ];

  static Map<AdminSiteAnimationMembership, String> defaultEntranceIds() => {
        AdminSiteAnimationMembership.normal: 'anim_entrance_normal',
        AdminSiteAnimationMembership.gold: 'anim_entrance_gold_crown',
        AdminSiteAnimationMembership.premium: 'anim_entrance_premium_star',
        AdminSiteAnimationMembership.diamond: 'anim_entrance_diamond_burst',
        AdminSiteAnimationMembership.vip: 'anim_entrance_vip_galaxy',
        AdminSiteAnimationMembership.svip: 'anim_entrance_svip_emperor',
        AdminSiteAnimationMembership.admin: 'anim_entrance_admin_galaxy',
        AdminSiteAnimationMembership.host: 'anim_host_seat_crown',
      };

  static List<AdminSiteAnimation> _entrance() => [
        const AdminSiteAnimation(
          id: 'anim_entrance_normal',
          name: 'Normal Giriş — Hoş geldin',
          category: AdminSiteAnimationCategory.entrance,
          membership: AdminSiteAnimationMembership.normal,
          durationMs: 2500,
          priority: 50,
          description: 'Mavi halka, sade banner — 2.5 sn',
          previewMp4Key: null,
        ),
        const AdminSiteAnimation(
          id: 'anim_entrance_gold_crown',
          name: 'Golden Crown — Gold Üye Girişi',
          category: AdminSiteAnimationCategory.entrance,
          membership: AdminSiteAnimationMembership.gold,
          durationMs: 3000,
          priority: 70,
          description: 'Altın taç + glow + VIP rozeti',
          previewMp4Key: 'gold_uye_girisi.mp4',
        ),
        const AdminSiteAnimation(
          id: 'anim_entrance_premium_star',
          name: 'Premium Star — Premium Üye Girişi',
          category: AdminSiteAnimationCategory.entrance,
          membership: AdminSiteAnimationMembership.premium,
          durationMs: 4000,
          priority: 80,
          description: 'Mor yıldız + kanat efekti',
          previewMp4Key: 'premium_uye_girisi.mp4',
        ),
        const AdminSiteAnimation(
          id: 'anim_entrance_diamond_burst',
          name: 'Diamond Burst — Diamond Üye Girişi',
          category: AdminSiteAnimationCategory.entrance,
          membership: AdminSiteAnimationMembership.diamond,
          durationMs: 4000,
          priority: 90,
          rarity: AdminSiteAnimationRarity.epic,
          description: 'Mavi kristal patlaması',
          previewMp4Key: 'diamond_uye_girisi.mp4',
        ),
        const AdminSiteAnimation(
          id: 'anim_entrance_vip_galaxy',
          name: 'Galaxy VIP — VIP Üye Girişi',
          category: AdminSiteAnimationCategory.entrance,
          membership: AdminSiteAnimationMembership.vip,
          durationMs: 4000,
          priority: 65,
          rarity: AdminSiteAnimationRarity.rare,
          description: 'Mor galaksi halkası',
        ),
        const AdminSiteAnimation(
          id: 'anim_entrance_svip_emperor',
          name: 'Dragon Emperor — SVIP Girişi',
          category: AdminSiteAnimationCategory.entrance,
          membership: AdminSiteAnimationMembership.svip,
          durationMs: 4000,
          priority: 85,
          rarity: AdminSiteAnimationRarity.legendary,
          description: 'EMPEROR rozeti + altın ışın',
        ),
        const AdminSiteAnimation(
          id: 'anim_entrance_admin_galaxy',
          name: 'Admin Galaxy — Site Admin Girişi',
          category: AdminSiteAnimationCategory.entrance,
          membership: AdminSiteAnimationMembership.admin,
          durationMs: 4000,
          priority: 100,
          rarity: AdminSiteAnimationRarity.legendary,
          anchor: AdminSiteAnimationAnchor.topLeft,
          description: 'ADMIN rozeti + mor kanat + galaxy',
          previewMp4Key: 'admin_girisi.mp4',
        ),
      ];

  static List<AdminSiteAnimation> _exit() => [
        const AdminSiteAnimation(
          id: 'anim_exit_normal',
          name: 'Normal Çıkış — Güle güle',
          category: AdminSiteAnimationCategory.exit,
          membership: AdminSiteAnimationMembership.normal,
          durationMs: 2000,
          priority: 30,
        ),
        const AdminSiteAnimation(
          id: 'anim_exit_gold',
          name: 'Gold Çıkış — Tekrar bekleriz',
          category: AdminSiteAnimationCategory.exit,
          membership: AdminSiteAnimationMembership.gold,
          durationMs: 2000,
          priority: 35,
        ),
        const AdminSiteAnimation(
          id: 'anim_exit_premium',
          name: 'Premium Çıkış — Yine bekleriz',
          category: AdminSiteAnimationCategory.exit,
          membership: AdminSiteAnimationMembership.premium,
          durationMs: 3000,
          priority: 36,
        ),
        const AdminSiteAnimation(
          id: 'anim_exit_diamond',
          name: 'Diamond Çıkış — Işıkla kal',
          category: AdminSiteAnimationCategory.exit,
          membership: AdminSiteAnimationMembership.diamond,
          durationMs: 3000,
          priority: 37,
        ),
        const AdminSiteAnimation(
          id: 'anim_exit_vip',
          name: 'VIP Çıkış — Kral geri dönecek',
          category: AdminSiteAnimationCategory.exit,
          membership: AdminSiteAnimationMembership.vip,
          durationMs: 3000,
          priority: 38,
        ),
        const AdminSiteAnimation(
          id: 'anim_exit_admin',
          name: 'Admin Çıkış — Sistemden ayrıldı',
          category: AdminSiteAnimationCategory.exit,
          membership: AdminSiteAnimationMembership.admin,
          durationMs: 3000,
          priority: 40,
        ),
      ];

  static List<AdminSiteAnimation> _transition() => [
        const AdminSiteAnimation(
          id: 'anim_transition_seat_change',
          name: 'Koltuk Değiştirme',
          category: AdminSiteAnimationCategory.transition,
          membership: AdminSiteAnimationMembership.all,
          durationMs: 2000,
          priority: 45,
          anchor: AdminSiteAnimationAnchor.seat,
        ),
        const AdminSiteAnimation(
          id: 'anim_transition_stage_up',
          name: 'Sahneye Geçiş',
          category: AdminSiteAnimationCategory.transition,
          membership: AdminSiteAnimationMembership.all,
          durationMs: 3000,
          priority: 44,
        ),
        const AdminSiteAnimation(
          id: 'anim_transition_host_handover',
          name: 'Host Devir Teslimi',
          category: AdminSiteAnimationCategory.transition,
          membership: AdminSiteAnimationMembership.host,
          durationMs: 4000,
          priority: 95,
        ),
      ];

  static List<AdminSiteAnimation> _seat() => [
        _seatFx('anim_seat_normal', 'Normal Koltuk — Sade Işık Halesi',
            AdminSiteAnimationMembership.normal, 50),
        _seatFx('anim_seat_gold', 'Gold Koltuk — Altın Halka',
            AdminSiteAnimationMembership.gold, 70),
        _seatFx('anim_seat_premium', 'Premium Koltuk — Mor Yıldız',
            AdminSiteAnimationMembership.premium, 80),
        _seatFx('anim_seat_diamond', 'Diamond Koltuk — Kristal',
            AdminSiteAnimationMembership.diamond, 90),
        _seatFx('anim_seat_vip', 'VIP Koltuk — Kanat & Alev',
            AdminSiteAnimationMembership.vip, 65, rarity: AdminSiteAnimationRarity.rare),
        _seatFx('anim_seat_svip', 'SVIP Koltuk — Kraliyet',
            AdminSiteAnimationMembership.svip, 85, rarity: AdminSiteAnimationRarity.legendary),
        _seatFx('anim_seat_admin', 'Admin Koltuk — Taç',
            AdminSiteAnimationMembership.admin, 100),
      ];

  static AdminSiteAnimation _seatFx(
    String id,
    String name,
    AdminSiteAnimationMembership tier,
    int priority, {
    AdminSiteAnimationRarity rarity = AdminSiteAnimationRarity.common,
  }) =>
      AdminSiteAnimation(
        id: id,
        name: name,
        category: AdminSiteAnimationCategory.seat,
        membership: tier,
        durationMs: 0,
        priority: priority,
        rarity: rarity,
        anchor: AdminSiteAnimationAnchor.seat,
      );

  static List<AdminSiteAnimation> _roomWide() => [
        const AdminSiteAnimation(
          id: 'anim_room_gift_rain',
          name: 'Hediye Yağmuru',
          category: AdminSiteAnimationCategory.roomWide,
          membership: AdminSiteAnimationMembership.all,
          durationMs: 5000,
          priority: 60,
        ),
        const AdminSiteAnimation(
          id: 'anim_room_star_rain',
          name: 'Yıldız Yağmuru',
          category: AdminSiteAnimationCategory.roomWide,
          membership: AdminSiteAnimationMembership.all,
          durationMs: 5000,
          priority: 58,
        ),
        const AdminSiteAnimation(
          id: 'anim_room_diamond_storm',
          name: 'Diamond Fırtınası',
          category: AdminSiteAnimationCategory.roomWide,
          membership: AdminSiteAnimationMembership.diamond,
          durationMs: 6000,
          priority: 75,
        ),
        const AdminSiteAnimation(
          id: 'anim_room_love',
          name: 'Aşk Efekti',
          category: AdminSiteAnimationCategory.roomWide,
          membership: AdminSiteAnimationMembership.all,
          durationMs: 5000,
          priority: 55,
        ),
        const AdminSiteAnimation(
          id: 'anim_room_bravo',
          name: 'Tebrik — BRAVO',
          category: AdminSiteAnimationCategory.roomWide,
          membership: AdminSiteAnimationMembership.all,
          durationMs: 5000,
          priority: 62,
        ),
        const AdminSiteAnimation(
          id: 'anim_room_level_up',
          name: 'Seviye Atladı',
          category: AdminSiteAnimationCategory.roomWide,
          membership: AdminSiteAnimationMembership.all,
          durationMs: 4000,
          priority: 63,
        ),
      ];

  static List<AdminSiteAnimation> _mic() => [
        const AdminSiteAnimation(
          id: 'anim_mic_on',
          name: 'Mikrofon Açma',
          category: AdminSiteAnimationCategory.mic,
          membership: AdminSiteAnimationMembership.all,
          durationMs: 2000,
          priority: 40,
          previewMp4Key: 'mikrofon_acma.mp4',
        ),
        const AdminSiteAnimation(
          id: 'anim_mic_off',
          name: 'Mikrofon Kapatma',
          category: AdminSiteAnimationCategory.mic,
          membership: AdminSiteAnimationMembership.all,
          durationMs: 2000,
          priority: 40,
          previewMp4Key: 'mikrofon_kapatma.mp4',
        ),
      ];

  static List<AdminSiteAnimation> _host() => [
        const AdminSiteAnimation(
          id: 'anim_host_seat_crown',
          name: 'Host Koltuğu — Taç & Parıltı',
          category: AdminSiteAnimationCategory.host,
          membership: AdminSiteAnimationMembership.host,
          durationMs: 0,
          priority: 95,
          anchor: AdminSiteAnimationAnchor.seat,
          previewMp4Key: 'host_koltugu.mp4',
        ),
      ];
}
