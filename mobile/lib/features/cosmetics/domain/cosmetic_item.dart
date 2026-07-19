import 'package:equatable/equatable.dart';

import '../../vip_gold/domain/vip_tier.dart';
import 'cosmetic_effect_kind.dart';
import 'cosmetic_slot.dart';

class CosmeticItem extends Equatable {
  const CosmeticItem({
    required this.id,
    required this.slot,
    required this.name,
    required this.effectKind,
    this.previewUrl,
    this.assetUrl,
    this.requiredTier = VipTier.basic,
    this.requiredRole,
    this.animated = true,
    this.colors = const [],
    this.sortOrder = 0,
    this.active = true,
  });

  factory CosmeticItem.fromJson(Map<String, dynamic> json) {
    final slotRaw = json['slot']?.toString() ?? 'profileFrame';
    final slot = CosmeticSlot.values.firstWhere(
      (s) => s.apiKey == slotRaw || s.name == slotRaw,
      orElse: () => CosmeticSlot.profileFrame,
    );
    final render = json['render'];
    final renderMap = render is Map
        ? Map<String, dynamic>.from(render)
        : <String, dynamic>{};
    final type = renderMap['type']?.toString() ??
        json['effectType']?.toString() ??
        json['type']?.toString();
    final tierRaw = json['requiredMembership']?.toString() ??
        json['tier']?.toString() ??
        json['minTier']?.toString();
    final colorsRaw = renderMap['colors'] ?? json['colors'];
    final colors = <ColorSpec>[];
    if (colorsRaw is List) {
      for (final c in colorsRaw) {
        if (c is String) colors.add(ColorSpec(c));
      }
    }
    return CosmeticItem(
      id: json['id']?.toString() ?? '',
      slot: slot,
      name: json['name']?.toString() ?? 'Efekt',
      effectKind:
          CosmeticEffectKindX.parse(type) ?? CosmeticEffectKind.neonGlow,
      previewUrl: json['previewUrl']?.toString() ?? json['imageUrl']?.toString(),
      assetUrl: json['assetUrl']?.toString() ??
          (json['asset'] is Map
              ? (json['asset'] as Map)['url']?.toString()
              : null),
      requiredTier: VipTier.fromMembership(tierRaw),
      requiredRole: json['requiredRole']?.toString(),
      animated: json['animated'] != false,
      colors: colors,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      active: json['active'] != false && json['isActive'] != false,
    );
  }

  final String id;
  final CosmeticSlot slot;
  final String name;
  final CosmeticEffectKind effectKind;
  final String? previewUrl;
  final String? assetUrl;
  final VipTier requiredTier;
  final String? requiredRole;
  final bool animated;
  final List<ColorSpec> colors;
  final int sortOrder;
  final bool active;

  bool isUnlockedFor({
    required VipTier tier,
    String? role,
  }) {
    if (!active) return false;
    if (tier.index < requiredTier.index) return false;
    final req = requiredRole?.trim().toLowerCase();
    if (req != null && req.isNotEmpty) {
      final r = role?.trim().toLowerCase() ?? '';
      if (r != req && !r.contains(req)) return false;
    }
    return true;
  }

  @override
  List<Object?> get props =>
      [id, slot, name, effectKind, previewUrl, requiredTier, active];
}

class ColorSpec extends Equatable {
  const ColorSpec(this.hex);
  final String hex;
  @override
  List<Object?> get props => [hex];
}
