import '../domain/site_animation_asset.dart';
import '../domain/site_animation_catalog_entry.dart';
import '../domain/site_animation_command.dart';
import '../domain/site_animation_layout.dart';
import '../domain/site_animation_slot.dart';
import '../domain/site_animation_type.dart';
import 'site_animation_asset_registry.dart';

/// Admin katalog + kullanıcı atamalarını SSE komutuna uygular.
abstract final class SiteAnimationResolver {
  /// Pasif animasyon veya bilinçli bastırma durumunda `null` döner.
  static SiteAnimationCommand? resolve({
    required SiteAnimationCommand base,
    required SiteAnimationCatalogSnapshot catalog,
  }) {
    final entry = _pickEntry(base: base, catalog: catalog);
    if (entry == null) return base;
    if (!entry.isActive) return null;
    return _applyEntry(base, entry);
  }

  static SiteAnimationCatalogEntry? _pickEntry({
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
        if (assigned != null) return assigned;
      }
    }

    if (base.type.isEntrance) {
      final defaultId = catalog.entranceDefaults[base.tier];
      final fromDefault = catalog.byId(defaultId);
      if (fromDefault != null) return fromDefault;
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
    return tierMatch ?? categoryMatch;
  }

  static SiteAnimationCommand _applyEntry(
    SiteAnimationCommand base,
    SiteAnimationCatalogEntry entry,
  ) {
    final backendAsset = entry.assetUrl != null && entry.assetUrl!.isNotEmpty
        ? SiteAnimationAsset(
            url: entry.assetUrl,
            kind: _mediaKind(entry.animationType, entry.assetUrl!),
            previewMp4Key: entry.previewMp4Key,
          )
        : null;

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
      priorityOverride: entry.priority,
      catalogLabel: entry.description ?? entry.name,
    );
  }

  static SiteAnimationMediaKind _mediaKind(String type, String url) {
    return switch (type.toLowerCase()) {
      'lottie' || 'json' => SiteAnimationMediaKind.lottie,
      'video' || 'mp4' || 'webm' => SiteAnimationMediaKind.video,
      'svga' => SiteAnimationMediaKind.svga,
      'rive' => SiteAnimationMediaKind.rive,
      _ => url.endsWith('.json')
          ? SiteAnimationMediaKind.lottie
          : url.endsWith('.mp4') || url.endsWith('.webm')
              ? SiteAnimationMediaKind.video
              : SiteAnimationMediaKind.native,
    };
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
