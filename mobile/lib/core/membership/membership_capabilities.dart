import '../../features/vip_gold/domain/vip_tier.dart';
import 'membership_capability_keys.dart';

/// Tek bir capability grant (admin matrisinden veya API).
class MembershipFeatureGrant {
  const MembershipFeatureGrant({
    required this.enabled,
    this.limitValue,
    this.dailyLimit,
    this.monthlyLimit,
    this.priority = 0,
    this.assetRef,
    this.metadata,
  });

  final bool enabled;
  final int? limitValue;
  final int? dailyLimit;
  final int? monthlyLimit;
  final int priority;
  final String? assetRef;
  final Map<String, dynamic>? metadata;

  factory MembershipFeatureGrant.fromJson(Map<String, dynamic> json) {
    return MembershipFeatureGrant(
      enabled: json['enabled'] == true || json['enabled'] == 'true',
      limitValue: _intOrNull(json['limitValue'] ?? json['limit']),
      dailyLimit: _intOrNull(json['dailyLimit']),
      monthlyLimit: _intOrNull(json['monthlyLimit']),
      priority: _intOrNull(json['priority']) ?? 0,
      assetRef: json['assetRef']?.toString(),
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  static int? _intOrNull(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}

/// Oturum capability snapshot — UI ve istemci tarafı ön kontroller.
class MembershipCapabilities {
  const MembershipCapabilities({
    required this.tier,
    this.expiresAt,
    this.discoveryWeight = 1.0,
    this.grants = const {},
    this.source = MembershipCapabilitySource.fallback,
  });

  final VipTier tier;
  final DateTime? expiresAt;
  final double discoveryWeight;
  final Map<String, MembershipFeatureGrant> grants;
  final MembershipCapabilitySource source;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  VipTier get effectiveTier => isExpired ? VipTier.basic : tier;

  bool allows(String key) {
    final g = grants[key];
    if (g != null) return g.enabled;
    return _fallbackAllows(effectiveTier, key);
  }

  int? limitFor(String key) {
    final g = grants[key];
    if (g != null && g.enabled) return g.limitValue;
    return _fallbackLimit(effectiveTier, key);
  }

  static MembershipCapabilities parse(
    Map<String, dynamic> json, {
    VipTier? fallbackTier,
  }) {
    final tierRaw = json['membership_level'] ??
        json['membershipLevel'] ??
        json['tier'] ??
        json['membership'] ??
        json['level'];
    final tier = VipTier.fromMembership(tierRaw?.toString());
    final expiresRaw = json['expires_at'] ??
        json['expiresAt'] ??
        json['membershipExpiresAt'];
    final expiresAt = expiresRaw != null
        ? DateTime.tryParse(expiresRaw.toString())
        : null;

    final weight = (json['discoveryWeight'] ?? json['discovery_weight']);
    final discoveryWeight = weight is num
        ? weight.toDouble()
        : double.tryParse(weight?.toString() ?? '') ?? _defaultWeight(tier);

    final grants = <String, MembershipFeatureGrant>{};
    final capRoot = json['capabilities'] ??
        json['features'] ??
        json['entitlements'];
    if (capRoot is Map) {
      for (final e in capRoot.entries) {
        final k = e.key.toString();
        final v = e.value;
        if (v is Map) {
          grants[k] = MembershipFeatureGrant.fromJson(
            Map<String, dynamic>.from(v),
          );
        } else if (v == true) {
          grants[k] = const MembershipFeatureGrant(enabled: true);
        }
      }
    } else if (capRoot is List) {
      for (final item in capRoot) {
        if (item is! Map) continue;
        final m = Map<String, dynamic>.from(item);
        final k = (m['key'] ?? m['featureKey'] ?? m['id'])?.toString();
        if (k == null || k.isEmpty) continue;
        grants[k] = MembershipFeatureGrant.fromJson(m);
      }
    }

    final hasApiGrants = grants.isNotEmpty;
    return MembershipCapabilities(
      tier: fallbackTier != null && tier == VipTier.basic
          ? fallbackTier
          : tier,
      expiresAt: expiresAt,
      discoveryWeight: discoveryWeight,
      grants: hasApiGrants ? grants : _fallbackGrantsForTier(tier),
      source: hasApiGrants
          ? MembershipCapabilitySource.api
          : MembershipCapabilitySource.fallback,
    );
  }

  static MembershipCapabilities forTier(VipTier tier) {
    return MembershipCapabilities(
      tier: tier,
      discoveryWeight: _defaultWeight(tier),
      grants: _fallbackGrantsForTier(tier),
      source: MembershipCapabilitySource.fallback,
    );
  }

  static double _defaultWeight(VipTier tier) => switch (tier) {
        VipTier.basic => 1.0,
        VipTier.gold => 1.1,
        VipTier.premium => 1.2,
        VipTier.diamond => 1.3,
        VipTier.svip => 1.4,
      };

  static bool _fallbackAllows(VipTier tier, String key) {
    final min = _minTierForKey(key);
    if (min == null) return false;
    return tier.isAtLeast(min);
  }

  static int? _fallbackLimit(VipTier tier, String key) {
    if (key == MembershipCapabilityKeys.profileVisitors) {
      if (tier.isAtLeast(VipTier.diamond) || tier == VipTier.svip) {
        return null;
      }
      if (tier.isAtLeast(VipTier.premium)) return 100;
    }
    return null;
  }

  static VipTier? _minTierForKey(String key) => switch (key) {
        MembershipCapabilityKeys.adFree => VipTier.gold,
        MembershipCapabilityKeys.profileFrame => VipTier.gold,
        MembershipCapabilityKeys.entranceEffect => VipTier.gold,
        MembershipCapabilityKeys.entranceSound => VipTier.diamond,
        MembershipCapabilityKeys.vipRooms => VipTier.diamond,
        MembershipCapabilityKeys.hiddenOnline ||
        MembershipCapabilityKeys.hiddenRoomEntry ||
        MembershipCapabilityKeys.profileVisitors =>
          VipTier.premium,
        MembershipCapabilityKeys.discoveryPriority => VipTier.gold,
        MembershipCapabilityKeys.svipLounge => VipTier.svip,
        MembershipCapabilityKeys.prioritySupport => VipTier.diamond,
        MembershipCapabilityKeys.customId => VipTier.diamond,
        MembershipCapabilityKeys.messagePin => VipTier.premium,
        MembershipCapabilityKeys.seatEffect => VipTier.gold,
        MembershipCapabilityKeys.messageBubble => VipTier.premium,
        MembershipCapabilityKeys.nameEffect => VipTier.gold,
        MembershipCapabilityKeys.hideVipBadge => VipTier.premium,
        _ => null,
      };

  static Map<String, MembershipFeatureGrant> _fallbackGrantsForTier(
    VipTier tier,
  ) {
    final out = <String, MembershipFeatureGrant>{};
    for (final key in _allKeys) {
      final min = _minTierForKey(key);
      if (min == null) continue;
      if (!tier.isAtLeast(min)) continue;
      out[key] = MembershipFeatureGrant(
        enabled: true,
        limitValue: _fallbackLimit(tier, key),
      );
    }
    return out;
  }

  static const _allKeys = [
    MembershipCapabilityKeys.profileFrame,
    MembershipCapabilityKeys.entranceEffect,
    MembershipCapabilityKeys.entranceSound,
    MembershipCapabilityKeys.hiddenOnline,
    MembershipCapabilityKeys.profileVisitors,
    MembershipCapabilityKeys.discoveryPriority,
    MembershipCapabilityKeys.vipRooms,
    MembershipCapabilityKeys.svipLounge,
    MembershipCapabilityKeys.prioritySupport,
    MembershipCapabilityKeys.customId,
    MembershipCapabilityKeys.messagePin,
    MembershipCapabilityKeys.hideVipBadge,
    MembershipCapabilityKeys.adFree,
    MembershipCapabilityKeys.seatEffect,
    MembershipCapabilityKeys.messageBubble,
    MembershipCapabilityKeys.nameEffect,
    MembershipCapabilityKeys.hiddenRoomEntry,
  ];
}

enum MembershipCapabilitySource { api, fallback }
