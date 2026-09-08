import 'package:flutter/material.dart';

import '../../domain/site_animation_tier.dart';

/// Tasarım referansı §34 — giriş animasyonu görsel dili (CanlıFal paleti).
enum SiteAnimationEntranceFx {
  none,
  goldDust,
  fireCrown,
  starRing,
  angelWings,
  lightning,
  diamondBurst,
  galaxyRing,
  cosmicPortal,
  royalGate,
  spotlight,
  dragonEmperor,
  adminGalaxy,
  hostCrown,
}

class SiteAnimationEntranceTheme {
  const SiteAnimationEntranceTheme({
    required this.animationId,
    required this.label,
    required this.gradient,
    required this.borderColor,
    required this.iconBg,
    required this.iconColor,
    required this.icon,
    required this.badge,
    required this.fx,
    this.showChevron = true,
    this.compact = false,
  });

  final String animationId;
  final String label;
  final List<Color> gradient;
  final Color borderColor;
  final Color iconBg;
  final Color iconColor;
  final IconData icon;
  final String? badge;
  final SiteAnimationEntranceFx fx;
  final bool showChevron;
  final bool compact;

  static const _purple = Color(0xFF6D2CE8);
  static const _purpleLight = Color(0xFF8B4DFF);
  static const _magenta = Color(0xFFC026D3);
  static const _cyan = Color(0xFF00D9D9);
  static const _gold = Color(0xFFFFD45A);
  static const _bgDeep = Color(0xFF0E0524);

  static SiteAnimationEntranceTheme resolve({
    String? animationId,
    required SiteAnimationTier tier,
  }) {
    final id = animationId?.trim();
    if (id != null && id.isNotEmpty && _byId.containsKey(id)) {
      return _byId[id]!;
    }
    return _byTier[tier] ?? _byId['anim_entrance_normal']!;
  }

  static const _byId = <String, SiteAnimationEntranceTheme>{
    'anim_entrance_normal': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_normal',
      label: 'Normal Giriş',
      gradient: [Color(0xFF263238), Color(0xFF37474F)],
      borderColor: Color(0xFF546E7A),
      iconBg: Color(0x3300D9D9),
      iconColor: _cyan,
      icon: Icons.waving_hand_rounded,
      badge: null,
      fx: SiteAnimationEntranceFx.none,
    ),
    'anim_entrance_gold_crown': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_gold_crown',
      label: 'Golden Crown',
      gradient: [Color(0xFF4A148C), Color(0xFFFF8F00)],
      borderColor: _gold,
      iconBg: Color(0x44FFD54F),
      iconColor: _gold,
      icon: Icons.emoji_events_rounded,
      badge: 'GOLD',
      fx: SiteAnimationEntranceFx.goldDust,
    ),
    'anim_entrance_golden_spotlight': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_golden_spotlight',
      label: 'Golden Spotlight',
      gradient: [Color(0xFF311B92), Color(0xFFFFB300)],
      borderColor: _gold,
      iconBg: Color(0x55FFD54F),
      iconColor: _gold,
      icon: Icons.highlight_rounded,
      badge: 'PLATINUM',
      fx: SiteAnimationEntranceFx.spotlight,
    ),
    'anim_entrance_golden_dust': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_golden_dust',
      label: 'Golden Dust',
      gradient: [Color(0xFF3E2723), Color(0xFFFFB74D)],
      borderColor: Color(0xFFFFCA28),
      iconBg: Color(0x33FFD54F),
      iconColor: _gold,
      icon: Icons.grain_rounded,
      badge: 'GOLD',
      fx: SiteAnimationEntranceFx.goldDust,
    ),
    'anim_entrance_fire_crown': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_fire_crown',
      label: 'Fire Crown',
      gradient: [Color(0xFFBF360C), Color(0xFFFF6D00)],
      borderColor: Color(0xFFFF9100),
      iconBg: Color(0x44FF5722),
      iconColor: Color(0xFFFFAB40),
      icon: Icons.local_fire_department_rounded,
      badge: 'GOLD',
      fx: SiteAnimationEntranceFx.fireCrown,
    ),
    'anim_entrance_premium_star': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_premium_star',
      label: 'Premium Star',
      gradient: [_purple, _magenta],
      borderColor: _purpleLight,
      iconBg: Color(0x448B4DFF),
      iconColor: Colors.white,
      icon: Icons.star_rounded,
      badge: 'PREMIUM',
      fx: SiteAnimationEntranceFx.starRing,
    ),
    'anim_entrance_angel_wings': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_angel_wings',
      label: 'Angel Wings',
      gradient: [Color(0xFF4527A0), Color(0xFFE1BEE7)],
      borderColor: Colors.white70,
      iconBg: Color(0x33FFFFFF),
      iconColor: Colors.white,
      icon: Icons.air_rounded,
      badge: 'PREMIUM',
      fx: SiteAnimationEntranceFx.angelWings,
    ),
    'anim_entrance_royal_star': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_royal_star',
      label: 'Royal Star',
      gradient: [Color(0xFF1A237E), Color(0xFFFFD54F)],
      borderColor: _gold,
      iconBg: Color(0x44FFD54F),
      iconColor: _gold,
      icon: Icons.auto_awesome_rounded,
      badge: 'PREMIUM',
      fx: SiteAnimationEntranceFx.starRing,
    ),
    'anim_entrance_diamond_burst': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_diamond_burst',
      label: 'Diamond Burst',
      gradient: [Color(0xFF0D47A1), _cyan],
      borderColor: _cyan,
      iconBg: Color(0x447DF9FF),
      iconColor: _cyan,
      icon: Icons.diamond_rounded,
      badge: 'DIAMOND',
      fx: SiteAnimationEntranceFx.diamondBurst,
    ),
    'anim_entrance_lightning_diamond': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_lightning_diamond',
      label: 'Lightning Diamond',
      gradient: [Color(0xFF311B92), _cyan],
      borderColor: _cyan,
      iconBg: Color(0x5500D9D9),
      iconColor: _cyan,
      icon: Icons.bolt_rounded,
      badge: 'DIAMOND',
      fx: SiteAnimationEntranceFx.lightning,
    ),
    'anim_entrance_vip_galaxy': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_vip_galaxy',
      label: 'Galaxy VIP',
      gradient: [Color(0xFF4A0072), _magenta],
      borderColor: _magenta,
      iconBg: Color(0x44C026D3),
      iconColor: _magenta,
      icon: Icons.hub_rounded,
      badge: 'VIP',
      fx: SiteAnimationEntranceFx.galaxyRing,
    ),
    'anim_entrance_royal_gate': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_royal_gate',
      label: 'Royal Gate',
      gradient: [Color(0xFF3E2723), Color(0xFFFFD54F)],
      borderColor: _gold,
      iconBg: Color(0x55FFD54F),
      iconColor: _gold,
      icon: Icons.door_front_door_rounded,
      badge: 'VIP',
      fx: SiteAnimationEntranceFx.royalGate,
    ),
    'anim_entrance_cosmic_portal': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_cosmic_portal',
      label: 'Cosmic Portal',
      gradient: [_purple, _cyan],
      borderColor: _cyan,
      iconBg: Color(0x446D2CE8),
      iconColor: _cyan,
      icon: Icons.blur_circular_rounded,
      badge: 'VIP',
      fx: SiteAnimationEntranceFx.cosmicPortal,
    ),
    'anim_entrance_svip_emperor': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_svip_emperor',
      label: 'Dragon Emperor',
      gradient: [Color(0xFF880E4F), Color(0xFFFFD54F)],
      borderColor: Color(0xFFFF6EC7),
      iconBg: Color(0x44FF4081),
      iconColor: Color(0xFFFF6EC7),
      icon: Icons.whatshot_rounded,
      badge: 'EMPEROR',
      fx: SiteAnimationEntranceFx.dragonEmperor,
    ),
    'anim_entrance_admin_galaxy': SiteAnimationEntranceTheme(
      animationId: 'anim_entrance_admin_galaxy',
      label: 'Admin Galaxy',
      gradient: [Color(0xFF7F1D1D), _purple],
      borderColor: Color(0xFFFF5252),
      iconBg: Color(0x44FF5252),
      iconColor: Color(0xFFFF5252),
      icon: Icons.admin_panel_settings_rounded,
      badge: 'ADMIN',
      fx: SiteAnimationEntranceFx.adminGalaxy,
    ),
    'anim_host_seat_crown': SiteAnimationEntranceTheme(
      animationId: 'anim_host_seat_crown',
      label: 'Host Taç',
      gradient: [Color(0xFF4A148C), _gold],
      borderColor: _gold,
      iconBg: Color(0x55FFD54F),
      iconColor: _gold,
      icon: Icons.star_rounded,
      badge: 'HOST',
      fx: SiteAnimationEntranceFx.hostCrown,
    ),
  };

  static final _byTier = <SiteAnimationTier, SiteAnimationEntranceTheme>{
    SiteAnimationTier.normal: _byId['anim_entrance_normal']!,
    SiteAnimationTier.gold: _byId['anim_entrance_gold_crown']!,
    SiteAnimationTier.premium: _byId['anim_entrance_golden_spotlight']!,
    SiteAnimationTier.diamond: _byId['anim_entrance_diamond_burst']!,
    SiteAnimationTier.vip: _byId['anim_entrance_royal_gate']!,
    SiteAnimationTier.svip: _byId['anim_entrance_vip_galaxy']!,
    SiteAnimationTier.admin: _byId['anim_entrance_admin_galaxy']!,
    SiteAnimationTier.host: _byId['anim_host_seat_crown']!,
  };

  static List<String> get allEntranceIds =>
      _byId.keys.where((k) => k.startsWith('anim_entrance_')).toList();
}
