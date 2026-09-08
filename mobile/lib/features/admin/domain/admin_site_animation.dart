import 'package:equatable/equatable.dart';

/// Site animasyon kategorisi — admin kütüphanesi (16 ana bölüm).
enum AdminSiteAnimationCategory {
  entrance,
  exit,
  transition,
  profile,
  profileFrame,
  avatarEffect,
  vipEffect,
  goldEffect,
  diamondEffect,
  badge,
  gift,
  voiceRoom,
  liveStream,
  game,
  reward,
  system,
  seat,
  roomWide,
  mic,
  host;

  String get label => switch (this) {
        AdminSiteAnimationCategory.entrance => 'Giriş',
        AdminSiteAnimationCategory.exit => 'Çıkış',
        AdminSiteAnimationCategory.transition => 'Geçiş',
        AdminSiteAnimationCategory.profile => 'Profil',
        AdminSiteAnimationCategory.profileFrame => 'Profil çerçevesi',
        AdminSiteAnimationCategory.avatarEffect => 'Avatar efekti',
        AdminSiteAnimationCategory.vipEffect => 'VIP efekti',
        AdminSiteAnimationCategory.goldEffect => 'Gold efekti',
        AdminSiteAnimationCategory.diamondEffect => 'Diamond efekti',
        AdminSiteAnimationCategory.badge => 'Rozet',
        AdminSiteAnimationCategory.gift => 'Hediye',
        AdminSiteAnimationCategory.voiceRoom => 'Sesli oda',
        AdminSiteAnimationCategory.liveStream => 'Canlı yayın',
        AdminSiteAnimationCategory.game => 'Oyun',
        AdminSiteAnimationCategory.reward => 'Ödül',
        AdminSiteAnimationCategory.system => 'Sistem',
        AdminSiteAnimationCategory.seat => 'Koltuk',
        AdminSiteAnimationCategory.roomWide => 'Oda geneli',
        AdminSiteAnimationCategory.mic => 'Mikrofon',
        AdminSiteAnimationCategory.host => 'Host',
      };

  /// Hub'da gösterilen 16 ana kategori.
  static const hubCategories = [
    AdminSiteAnimationCategory.entrance,
    AdminSiteAnimationCategory.exit,
    AdminSiteAnimationCategory.transition,
    AdminSiteAnimationCategory.profile,
    AdminSiteAnimationCategory.profileFrame,
    AdminSiteAnimationCategory.avatarEffect,
    AdminSiteAnimationCategory.vipEffect,
    AdminSiteAnimationCategory.goldEffect,
    AdminSiteAnimationCategory.diamondEffect,
    AdminSiteAnimationCategory.badge,
    AdminSiteAnimationCategory.gift,
    AdminSiteAnimationCategory.voiceRoom,
    AdminSiteAnimationCategory.liveStream,
    AdminSiteAnimationCategory.game,
    AdminSiteAnimationCategory.reward,
    AdminSiteAnimationCategory.system,
  ];

  static AdminSiteAnimationCategory? parse(String? raw) {
    final k = raw?.toLowerCase().trim().replaceAll(' ', '_') ?? '';
    return switch (k) {
      'entrance' ||
      'giris' ||
      'giriş' ||
      'member_joined' =>
        AdminSiteAnimationCategory.entrance,
      'exit' || 'cikis' || 'çıkış' || 'member_left' =>
        AdminSiteAnimationCategory.exit,
      'transition' || 'gecis' || 'geçiş' || 'seat_change' =>
        AdminSiteAnimationCategory.transition,
      'profile' || 'profil' || 'profile_animation' =>
        AdminSiteAnimationCategory.profile,
      'profile_frame' ||
      'profileframe' ||
      'frame' =>
        AdminSiteAnimationCategory.profileFrame,
      'avatar' ||
      'avatar_effect' ||
      'avatareffect' =>
        AdminSiteAnimationCategory.avatarEffect,
      'vip' || 'vip_effect' || 'vipeffect' =>
        AdminSiteAnimationCategory.vipEffect,
      'gold' || 'gold_effect' || 'goldeffect' =>
        AdminSiteAnimationCategory.goldEffect,
      'diamond' ||
      'diamond_effect' ||
      'diamondeffect' =>
        AdminSiteAnimationCategory.diamondEffect,
      'badge' || 'rozet' => AdminSiteAnimationCategory.badge,
      'gift' || 'hediye' => AdminSiteAnimationCategory.gift,
      'voice_room' ||
      'voiceroom' ||
      'sesli_oda' ||
      'voice' =>
        AdminSiteAnimationCategory.voiceRoom,
      'live' ||
      'live_stream' ||
      'livestream' ||
      'canli' =>
        AdminSiteAnimationCategory.liveStream,
      'game' || 'oyun' => AdminSiteAnimationCategory.game,
      'reward' || 'odul' || 'ödül' => AdminSiteAnimationCategory.reward,
      'system' || 'sistem' => AdminSiteAnimationCategory.system,
      'seat' || 'koltuk' => AdminSiteAnimationCategory.seat,
      'room_wide' ||
      'roomwide' ||
      'oda_geneli' ||
      'room' =>
        AdminSiteAnimationCategory.roomWide,
      'mic' || 'mikrofon' => AdminSiteAnimationCategory.mic,
      'host' => AdminSiteAnimationCategory.host,
      _ => null,
    };
  }
}

enum AdminSiteAnimationMembership {
  normal,
  gold,
  premium,
  diamond,
  vip,
  svip,
  admin,
  host,
  all;

  String get label => switch (this) {
        AdminSiteAnimationMembership.normal => 'NORMAL',
        AdminSiteAnimationMembership.gold => 'GOLD',
        AdminSiteAnimationMembership.premium => 'PREMIUM',
        AdminSiteAnimationMembership.diamond => 'DIAMOND',
        AdminSiteAnimationMembership.vip => 'VIP',
        AdminSiteAnimationMembership.svip => 'SVIP',
        AdminSiteAnimationMembership.admin => 'ADMIN',
        AdminSiteAnimationMembership.host => 'HOST',
        AdminSiteAnimationMembership.all => 'Tümü',
      };

  static AdminSiteAnimationMembership? parse(String? raw) {
    final k = raw?.toLowerCase().trim() ?? '';
    return switch (k) {
      'normal' || 'basic' || 'uye' => AdminSiteAnimationMembership.normal,
      'gold' => AdminSiteAnimationMembership.gold,
      'premium' => AdminSiteAnimationMembership.premium,
      'diamond' => AdminSiteAnimationMembership.diamond,
      'vip' => AdminSiteAnimationMembership.vip,
      'svip' || 'super_vip' => AdminSiteAnimationMembership.svip,
      'admin' => AdminSiteAnimationMembership.admin,
      'host' || 'owner' => AdminSiteAnimationMembership.host,
      'all' || '*' => AdminSiteAnimationMembership.all,
      _ => null,
    };
  }
}

enum AdminSiteAnimationAnchor {
  topLeft,
  topCenter,
  seat,
  center,
  custom;

  String get wire => switch (this) {
        AdminSiteAnimationAnchor.topLeft => 'TOP_LEFT',
        AdminSiteAnimationAnchor.topCenter => 'TOP_CENTER',
        AdminSiteAnimationAnchor.seat => 'SEAT',
        AdminSiteAnimationAnchor.center => 'CENTER',
        AdminSiteAnimationAnchor.custom => 'CUSTOM',
      };

  static AdminSiteAnimationAnchor parse(String? raw) {
    return switch (raw?.toUpperCase()) {
      'TOP_CENTER' || 'TOPCENTER' => AdminSiteAnimationAnchor.topCenter,
      'SEAT' => AdminSiteAnimationAnchor.seat,
      'CENTER' => AdminSiteAnimationAnchor.center,
      'CUSTOM' => AdminSiteAnimationAnchor.custom,
      _ => AdminSiteAnimationAnchor.topLeft,
    };
  }
}

enum AdminSiteAnimationRarity {
  common,
  rare,
  epic,
  legendary;

  static AdminSiteAnimationRarity parse(String? raw) {
    return switch (raw?.toLowerCase()) {
      'rare' => AdminSiteAnimationRarity.rare,
      'epic' => AdminSiteAnimationRarity.epic,
      'legendary' => AdminSiteAnimationRarity.legendary,
      _ => AdminSiteAnimationRarity.common,
    };
  }
}

enum AdminSiteAnimationDurationPreset {
  unlimited,
  days1,
  days7,
  days30,
  days90,
  custom;

  String get label => switch (this) {
        AdminSiteAnimationDurationPreset.unlimited => 'Süresiz',
        AdminSiteAnimationDurationPreset.days1 => '1 gün',
        AdminSiteAnimationDurationPreset.days7 => '7 gün',
        AdminSiteAnimationDurationPreset.days30 => '30 gün',
        AdminSiteAnimationDurationPreset.days90 => '90 gün',
        AdminSiteAnimationDurationPreset.custom => 'Özel tarih',
      };
}

/// Kullanıcıya atanabilir animasyon slotları.
enum AdminSiteAnimationSlot {
  entrance,
  exit,
  profile,
  profileFrame,
  avatar,
  seat,
  mic,
  vip,
  gift;

  String get label => switch (this) {
        AdminSiteAnimationSlot.entrance => 'Entrance',
        AdminSiteAnimationSlot.exit => 'Exit',
        AdminSiteAnimationSlot.profile => 'Profile',
        AdminSiteAnimationSlot.profileFrame => 'Profile Frame',
        AdminSiteAnimationSlot.avatar => 'Avatar',
        AdminSiteAnimationSlot.seat => 'Seat',
        AdminSiteAnimationSlot.mic => 'Mic',
        AdminSiteAnimationSlot.vip => 'VIP',
        AdminSiteAnimationSlot.gift => 'Gift',
      };
}

class AdminSiteAnimationStats extends Equatable {
  const AdminSiteAnimationStats({
    this.total = 0,
    this.active = 0,
    this.inactive = 0,
    this.entrance = 0,
    this.exit = 0,
    this.seat = 0,
    this.vip = 0,
    this.profileFrame = 0,
    this.gift = 0,
  });

  factory AdminSiteAnimationStats.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return AdminSiteAnimationStats(
      total: n(json['total']),
      active: n(json['active']),
      inactive: n(json['inactive'] ?? json['passive']),
      entrance: n(json['entrance'] ?? json['entry']),
      exit: n(json['exit']),
      seat: n(json['seat']),
      vip: n(json['vip']),
      profileFrame: n(json['profileFrame'] ?? json['profile_frame']),
      gift: n(json['gift']),
    );
  }

  factory AdminSiteAnimationStats.fromList(List<AdminSiteAnimation> items) {
    var active = 0;
    var entrance = 0;
    var exit = 0;
    var seat = 0;
    var vip = 0;
    var profileFrame = 0;
    var gift = 0;
    for (final a in items) {
      if (a.isActive) active++;
      switch (a.category) {
        case AdminSiteAnimationCategory.entrance:
          entrance++;
        case AdminSiteAnimationCategory.exit:
          exit++;
        case AdminSiteAnimationCategory.seat:
          seat++;
        case AdminSiteAnimationCategory.profileFrame:
          profileFrame++;
        case AdminSiteAnimationCategory.gift:
          gift++;
        default:
          break;
      }
      if (a.membership == AdminSiteAnimationMembership.vip ||
          a.membership == AdminSiteAnimationMembership.svip) {
        vip++;
      }
    }
    return AdminSiteAnimationStats(
      total: items.length,
      active: active,
      inactive: items.length - active,
      entrance: entrance,
      exit: exit,
      seat: seat,
      vip: vip,
      profileFrame: profileFrame,
      gift: gift,
    );
  }

  final int total;
  final int active;
  final int inactive;
  final int entrance;
  final int exit;
  final int seat;
  final int vip;
  final int profileFrame;
  final int gift;

  @override
  List<Object?> get props => [
        total,
        active,
        inactive,
        entrance,
        exit,
        seat,
        vip,
        profileFrame,
        gift,
      ];
}

class AdminSiteAnimation extends Equatable {
  const AdminSiteAnimation({
    required this.id,
    required this.name,
    required this.category,
    required this.membership,
    this.animationType = 'native',
    this.assetUrl,
    this.previewUrl,
    this.soundUrl,
    this.durationMs = 3000,
    this.priority = 50,
    this.rarity = AdminSiteAnimationRarity.common,
    this.context = 'voice_room',
    this.anchor = AdminSiteAnimationAnchor.topLeft,
    this.scale = 1,
    this.cooldownMs = 0,
    this.isActive = true,
    this.description,
    this.previewMp4Key,
  });

  factory AdminSiteAnimation.fromJson(Map<String, dynamic> json) {
    return AdminSiteAnimation(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Animasyon',
      category: AdminSiteAnimationCategory.parse(
            json['category']?.toString(),
          ) ??
          AdminSiteAnimationCategory.entrance,
      membership: AdminSiteAnimationMembership.parse(
            json['membership']?.toString(),
          ) ??
          AdminSiteAnimationMembership.normal,
      animationType: json['animationType']?.toString() ??
          json['assetType']?.toString() ??
          'native',
      assetUrl: json['assetUrl']?.toString() ?? json['animationUrl']?.toString(),
      previewUrl: json['previewUrl']?.toString() ??
          json['thumbnailUrl']?.toString(),
      soundUrl: json['soundUrl']?.toString(),
      durationMs: _int(json['durationMs'] ?? json['duration'], 3000),
      priority: _int(json['priority'], 50),
      rarity: AdminSiteAnimationRarity.parse(json['rarity']?.toString()),
      context: json['context']?.toString() ?? 'voice_room',
      anchor: AdminSiteAnimationAnchor.parse(json['anchor']?.toString()),
      scale: _double(json['scale'], 1),
      cooldownMs: _int(json['cooldownMs'] ?? json['cooldown'], 0),
      isActive: json['isActive'] != false && json['active'] != false,
      description: json['description']?.toString(),
      previewMp4Key: json['previewMp4Key']?.toString(),
    );
  }

  final String id;
  final String name;
  final AdminSiteAnimationCategory category;
  final AdminSiteAnimationMembership membership;
  final String animationType;
  final String? assetUrl;
  final String? previewUrl;
  final String? soundUrl;
  final int durationMs;
  final int priority;
  final AdminSiteAnimationRarity rarity;
  final String context;
  final AdminSiteAnimationAnchor anchor;
  final double scale;
  final int cooldownMs;
  final bool isActive;
  final String? description;
  final String? previewMp4Key;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'membership': membership.name,
        'animationType': animationType,
        if (assetUrl != null) 'assetUrl': assetUrl,
        if (previewUrl != null) 'previewUrl': previewUrl,
        if (soundUrl != null) 'soundUrl': soundUrl,
        'durationMs': durationMs,
        'priority': priority,
        'rarity': rarity.name,
        'context': context,
        'anchor': anchor.wire,
        'scale': scale,
        'cooldownMs': cooldownMs,
        'isActive': isActive,
        if (description != null) 'description': description,
        if (previewMp4Key != null) 'previewMp4Key': previewMp4Key,
      };

  AdminSiteAnimation copyWith({
    String? name,
    AdminSiteAnimationCategory? category,
    AdminSiteAnimationMembership? membership,
    String? animationType,
    String? assetUrl,
    String? previewUrl,
    String? soundUrl,
    int? durationMs,
    int? priority,
    AdminSiteAnimationRarity? rarity,
    String? context,
    AdminSiteAnimationAnchor? anchor,
    double? scale,
    int? cooldownMs,
    bool? isActive,
    String? description,
  }) {
    return AdminSiteAnimation(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      membership: membership ?? this.membership,
      animationType: animationType ?? this.animationType,
      assetUrl: assetUrl ?? this.assetUrl,
      previewUrl: previewUrl ?? this.previewUrl,
      soundUrl: soundUrl ?? this.soundUrl,
      durationMs: durationMs ?? this.durationMs,
      priority: priority ?? this.priority,
      rarity: rarity ?? this.rarity,
      context: context ?? this.context,
      anchor: anchor ?? this.anchor,
      scale: scale ?? this.scale,
      cooldownMs: cooldownMs ?? this.cooldownMs,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      previewMp4Key: previewMp4Key,
    );
  }

  static int _int(dynamic v, int fallback) {
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? fallback;
  }

  static double _double(dynamic v, double fallback) {
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? fallback;
  }

  @override
  List<Object?> get props => [id, name, category, membership, isActive];
}

class AdminSiteAnimationAssignment extends Equatable {
  const AdminSiteAnimationAssignment({
    required this.userId,
    required this.slot,
    this.animationId,
    this.expiresAt,
  });

  final String userId;
  final AdminSiteAnimationSlot slot;
  final String? animationId;
  final DateTime? expiresAt;

  @override
  List<Object?> get props => [userId, slot, animationId];
}
