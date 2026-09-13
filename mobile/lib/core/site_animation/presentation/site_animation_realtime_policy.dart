import '../../../core/util/json_util.dart';
import '../../../features/profile/presentation/premium_2026/profile_membership_helpers.dart';
import '../../../features/vip_gold/domain/vip_tier.dart';
import '../domain/site_animation_tier.dart';
import '../domain/site_animation_type.dart';

/// SSE / room_event payload içinden olay zamanı (ms).
int? siteAnimationEventTimestampMs(Map<String, dynamic> payload) {
  for (final key in const [
    'timestamp',
    'ts',
    'createdAt',
    'createdAtMs',
    'eventTime',
    'occurredAt',
  ]) {
    final v = payload[key];
    if (v == null) continue;
    if (v is num) return v.toInt();
    if (v is String) {
      final asInt = int.tryParse(v);
      if (asInt != null) return asInt;
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed.millisecondsSinceEpoch;
    }
  }
  final nested = payload['data'];
  if (nested is Map) {
    return siteAnimationEventTimestampMs(Map<String, dynamic>.from(nested));
  }
  return null;
}

int? _membershipDaysRemainingFromPayload(Map<String, dynamic> payload) {
  for (final key in const [
    'membershipDaysRemaining',
    'daysRemaining',
    'vipDaysRemaining',
    'subscriptionDaysRemaining',
  ]) {
    final v = payload[key];
    if (v is num) return v.toInt();
    if (v is String) {
      final n = int.tryParse(v);
      if (n != null) return n;
    }
  }
  final membership = payload['membership'];
  if (membership is Map) {
    return _membershipDaysRemainingFromPayload(
      Map<String, dynamic>.from(membership),
    );
  }
  return null;
}

String? _membershipRawFromPayload(Map<String, dynamic> payload) {
  final direct = pick(payload, [
    'membership',
    'tier',
    'vipTier',
    'vipLevel',
    'subscriptionTier',
  ])?.toString();
  if (direct != null && direct.trim().isNotEmpty) return direct.trim();
  final user = payload['user'];
  if (user is Map) {
    return pick(Map<String, dynamic>.from(user), [
      'membership',
      'tier',
      'vipTier',
    ])?.toString();
  }
  return null;
}

/// Aktif Gold+ üyelik (backend üyelik alanı; süre biliniyorsa dolmuş sayılır).
bool activeGoldEntranceMembershipFromPayload(Map<String, dynamic> payload) {
  final info = resolveProfileMembership(
    rawMembership: _membershipRawFromPayload(payload),
    daysRemaining: _membershipDaysRemainingFromPayload(payload),
  );
  return info.effectiveTier.hasEntranceFx;
}

bool siteAnimationTierAllowsEntranceExit(SiteAnimationTier tier) {
  final vip = switch (tier) {
    SiteAnimationTier.svip => VipTier.svip,
    SiteAnimationTier.diamond => VipTier.diamond,
    SiteAnimationTier.premium => VipTier.premium,
    SiteAnimationTier.gold => VipTier.gold,
    SiteAnimationTier.vip => VipTier.gold,
    SiteAnimationTier.admin => VipTier.basic,
    SiteAnimationTier.host => VipTier.basic,
    SiteAnimationTier.normal => VipTier.basic,
  };
  return vip.hasEntranceFx;
}

/// Giriş/çıkış kartı yalnızca gerçek zamanlı oturumda ve Gold+ için.
bool shouldPlayRealtimeMemberEntranceExit({
  required SiteAnimationType type,
  required Map<String, dynamic> payload,
  required bool effectsArmed,
  required int? sessionEpochMs,
  required bool memberWasAlreadyKnown,
}) {
  if (!type.isEntrance && !type.isExit) return true;
  if (!effectsArmed || sessionEpochMs == null) return false;
  if (memberWasAlreadyKnown) return false;
  if (!activeGoldEntranceMembershipFromPayload(payload)) return false;

  final eventMs = siteAnimationEventTimestampMs(payload);
  if (eventMs != null && eventMs < sessionEpochMs) return false;
  return true;
}
