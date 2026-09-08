import 'site_animation_asset.dart';
import 'site_animation_layout.dart';
import 'site_animation_tier.dart';
import 'site_animation_type.dart';

class SiteAnimationCommand {
  const SiteAnimationCommand({
    required this.eventId,
    required this.roomId,
    required this.type,
    required this.tier,
    required this.userId,
    required this.userName,
    this.avatarUrl,
    this.layout = const SiteAnimationLayout(),
    this.asset = const SiteAnimationAsset(),
    this.micOn,
    this.createdAtMs,
    this.priorityOverride,
    this.catalogLabel,
    this.animationId,
    this.soundUrl,
    this.cooldownMs = 0,
  });

  final String eventId;
  final String roomId;
  final SiteAnimationType type;
  final SiteAnimationTier tier;
  final String userId;
  final String userName;
  final String? avatarUrl;
  final SiteAnimationLayout layout;
  final SiteAnimationAsset asset;
  final bool? micOn;
  final int? createdAtMs;
  final int? priorityOverride;
  final String? catalogLabel;
  final String? animationId;
  final String? soundUrl;
  final int cooldownMs;

  String get cooldownKey =>
      '${userId.trim()}:${animationId ?? type.name}';

  int get priority {
    if (priorityOverride != null) return priorityOverride!;
    final base = tier.queuePriority;
    return switch (type) {
      SiteAnimationType.memberJoined ||
      SiteAnimationType.hostSeat =>
        base + 10,
      SiteAnimationType.seatChanged => base + 5,
      SiteAnimationType.micEnabled || SiteAnimationType.micDisabled => 40,
      SiteAnimationType.memberLeft => 30,
      SiteAnimationType.seatRankGlow => base,
    };
  }

  Duration get displayDuration {
    final ms = layout.durationMs;
    if (ms != null && ms >= 1500) {
      return Duration(milliseconds: ms.clamp(1500, 6000));
    }
    return switch (type) {
      SiteAnimationType.memberJoined ||
      SiteAnimationType.hostSeat =>
        const Duration(milliseconds: 3200),
      SiteAnimationType.memberLeft => const Duration(milliseconds: 2600),
      SiteAnimationType.seatChanged => const Duration(milliseconds: 2800),
      SiteAnimationType.micEnabled ||
      SiteAnimationType.micDisabled =>
        const Duration(milliseconds: 2200),
      SiteAnimationType.seatRankGlow => const Duration(milliseconds: 3000),
    };
  }

  SiteAnimationCommand copyWith({
    SiteAnimationLayout? layout,
    SiteAnimationAsset? asset,
    int? priorityOverride,
    String? catalogLabel,
    String? animationId,
    String? soundUrl,
    int? cooldownMs,
  }) {
    return SiteAnimationCommand(
      eventId: eventId,
      roomId: roomId,
      type: type,
      tier: tier,
      userId: userId,
      userName: userName,
      avatarUrl: avatarUrl,
      layout: layout ?? this.layout,
      asset: asset ?? this.asset,
      micOn: micOn,
      createdAtMs: createdAtMs,
      priorityOverride: priorityOverride ?? this.priorityOverride,
      catalogLabel: catalogLabel ?? this.catalogLabel,
      animationId: animationId ?? this.animationId,
      soundUrl: soundUrl ?? this.soundUrl,
      cooldownMs: cooldownMs ?? this.cooldownMs,
    );
  }
}
