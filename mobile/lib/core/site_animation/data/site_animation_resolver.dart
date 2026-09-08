import '../domain/site_animation_asset.dart';
import '../domain/site_animation_catalog_entry.dart';
import '../domain/site_animation_command.dart';
import '../domain/site_animation_layout.dart';
import '../domain/site_animation_slot.dart';
import '../domain/site_animation_tier.dart';
import '../domain/site_animation_type.dart';
import 'site_animation_asset_registry.dart';
import 'site_animation_cdn_assets.dart';

/// Site animasyon overlay kimlikleri — [SiteAnimationContext] ile hizalı.
abstract final class SiteAnimationOverlayIds {
  static const gift = 'ctx_gift';
  static const live = 'ctx_live';
}

/// Admin katalog + kullanıcı atamalarını SSE komutuna uygular.
abstract final class SiteAnimationResolver {
  /// Pasif animasyon veya bilinçli bastırma durumunda `null` döner.
  static SiteAnimationCommand? resolve({
    required SiteAnimationCommand base,
    required SiteAnimationCatalogSnapshot catalog,
  }) {
    final picked = _pickEntry(base: base, catalog: catalog);
    final entry = picked.entry;
    if (entry == null) return base;
    if (!entry.isActive) return null;
    return _applyEntry(
      base,
      entry,
      adminCustomPriority: picked.adminAssigned ? 110 : null,
    );
  }

  static ({SiteAnimationCatalogEntry? entry, bool adminAssigned}) _pickEntry({
    required SiteAnimationCommand base,
    required SiteAnimationCatalogSnapshot catalog,
  }) {
    final slot = _slotForType(base.type);
    if (slot != null) {
      final userSlots = catalog.userAssignments[base.userId];
      final assignment = userSlots?[slot];
      if (assignment != null &&
          !assignment.isExpired &&
          assignment.animationId.isNotEmpty) {
        final assigned = catalog.byId(assignment.animationId);
        if (assigned != null) {
          return (entry: assigned, adminAssigned: true);
        }
      }
    }

    if (base.type.isEntrance) {
      final defaultId = catalog.entranceDefaults[base.tier];
      final fromDefault = catalog.byId(defaultId);
      if (fromDefault != null) {
        return (entry: fromDefault, adminAssigned: false);
      }
    }

    if (base.type.isExit) {
      final defaultId = catalog.exitDefaults[base.tier];
      final fromDefault = catalog.byId(defaultId);
      if (fromDefault != null) {
        return (entry: fromDefault, adminAssigned: false);
      }
    }

    final category = _categoryForType(base.type);
    SiteAnimationCatalogEntry? tierMatch;
    SiteAnimationCatalogEntry? categoryMatch;
    for (final entry in catalog.animations.values) {
      if (!entry.isActive) continue;
      if (entry.category != category) continue;
      categoryMatch ??= entry;
      if (entry.tier == base.tier) {
        tierMatch = entry;
        break;
      }
    }
    return (entry: tierMatch ?? categoryMatch, adminAssigned: false);
  }

  /// Hediye vurgusu — gift kategorisi katalog girdisi uygular.
  static SiteAnimationCommand? resolveGiftHighlight({
    required String eventId,
    required String senderName,
    required String? senderId,
    required int jetonAmount,
    required SiteAnimationCatalogSnapshot catalog,
  }) {
    if (jetonAmount < 1000) return null;
    final tier = _tierFromJeton(jetonAmount);
    final base = SiteAnimationCommand(
      eventId: eventId,
      roomId: SiteAnimationOverlayIds.gift,
      type: SiteAnimationType.memberJoined,
      tier: tier,
      userId: senderId?.trim().isNotEmpty == true ? senderId!.trim() : senderName,
      userName: senderName,
      layout: const SiteAnimationLayout(
        anchor: SiteAnimationAnchor.topCenter,
        durationMs: 2800,
      ),
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    );

    final assignment = catalog.userAssignments[base.userId]?[SiteAnimationSlot.gift];
    if (assignment != null &&
        !assignment.isExpired &&
        assignment.animationId.isNotEmpty) {
      final assigned = catalog.byId(assignment.animationId);
      if (assigned != null && assigned.isActive) {
        return applyCatalogEntry(base, assigned, adminCustomPriority: 110);
      }
    }

    SiteAnimationCatalogEntry? tierMatch;
    SiteAnimationCatalogEntry? categoryMatch;
    for (final entry in catalog.animations.values) {
      if (!entry.isActive || entry.category != 'gift') continue;
      categoryMatch ??= entry;
      if (entry.tier == tier) {
        tierMatch = entry;
        break;
      }
    }
    final picked = tierMatch ?? categoryMatch;
    if (picked == null) return base;
    return applyCatalogEntry(base, picked);
  }

  static SiteAnimationTier _tierFromJeton(int jeton) {
    if (jeton >= 50000) return SiteAnimationTier.svip;
    if (jeton >= 10000) return SiteAnimationTier.vip;
    if (jeton >= 5000) return SiteAnimationTier.diamond;
    if (jeton >= 2500) return SiteAnimationTier.premium;
    if (jeton >= 1000) return SiteAnimationTier.gold;
    return SiteAnimationTier.normal;
  }

  static SiteAnimationCommand applyCatalogEntry(
    SiteAnimationCommand base,
    SiteAnimationCatalogEntry entry, {
    int? adminCustomPriority,
  }) {
    return _applyEntry(base, entry, adminCustomPriority: adminCustomPriority);
  }

  static SiteAnimationCommand _applyEntry(
    SiteAnimationCommand base,
    SiteAnimationCatalogEntry entry, {
    int? adminCustomPriority,
  }) {
    final backendAsset = SiteAnimationCdnAssets.runtimeAsset(entry);

    final asset = SiteAnimationAssetRegistry.resolve(
      type: base.type,
      tier: base.tier,
      backendAsset: backendAsset,
    );

    final layout = base.layout.copyWith(
      anchor: entry.anchor,
      scale: entry.scale,
      durationMs: entry.durationMs,
    );

    return base.copyWith(
      layout: layout,
      asset: asset,
      priorityOverride: adminCustomPriority ?? entry.priority,
      catalogLabel: entry.description ?? entry.name,
      animationId: entry.id,
      soundUrl: entry.soundUrl ?? base.soundUrl,
      cooldownMs: entry.cooldownMs > 0 ? entry.cooldownMs : base.cooldownMs,
    );
  }

  static SiteAnimationSlot? _slotForType(SiteAnimationType type) {
    return switch (type) {
      SiteAnimationType.memberJoined || SiteAnimationType.hostSeat =>
        SiteAnimationSlot.entrance,
      SiteAnimationType.memberLeft => SiteAnimationSlot.exit,
      SiteAnimationType.seatChanged => SiteAnimationSlot.seat,
      SiteAnimationType.micEnabled || SiteAnimationType.micDisabled =>
        SiteAnimationSlot.mic,
      SiteAnimationType.seatRankGlow => SiteAnimationSlot.seat,
    };
  }

  static String _categoryForType(SiteAnimationType type) {
    return switch (type) {
      SiteAnimationType.memberJoined => 'entrance',
      SiteAnimationType.hostSeat => 'host',
      SiteAnimationType.memberLeft => 'exit',
      SiteAnimationType.seatChanged => 'transition',
      SiteAnimationType.micEnabled || SiteAnimationType.micDisabled => 'mic',
      SiteAnimationType.seatRankGlow => 'seat',
    };
  }
}
