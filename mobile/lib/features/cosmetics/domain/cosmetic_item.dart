import 'package:equatable/equatable.dart';

import '../../vip_gold/domain/vip_tier.dart';
import 'cosmetic_effect_kind.dart';
import 'cosmetic_name_style.dart';
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
    this.nameStyle,
    this.assetType,
    this.durationMs,
    this.accessorySlot,
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
    final image = (json['assetUrl'] ?? json['imageUrl'])?.toString();
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
      // Sitedeki profil çerçeveleri yalnızca görsel (imageUrl) taşır; önceden
      // neon halka çiziliyordu, görselin kendisi gösterilmiyordu.
      effectKind: CosmeticEffectKindX.parse(type) ??
          ((image != null && image.trim().isNotEmpty)
              ? CosmeticEffectKind.imageOverlay
              : CosmeticEffectKind.neonGlow),
      previewUrl: json['previewUrl']?.toString() ?? json['imageUrl']?.toString(),
      assetUrl: json['assetUrl']?.toString() ??
          (json['asset'] is Map
              ? (json['asset'] as Map)['url']?.toString()
              : null) ??
          json['imageUrl']?.toString(),
      requiredTier: VipTier.fromMembership(tierRaw),
      requiredRole: json['requiredRole']?.toString(),
      animated: json['animated'] != false,
      colors: colors,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      active: json['active'] != false && json['isActive'] != false,
      nameStyle: CosmeticNameStyle.parse(json['cssPreset']),
      assetType: json['assetType']?.toString(),
      durationMs: (json['durationMs'] as num?)?.toInt(),
      accessorySlot: slot == CosmeticSlot.avatarAccessory
          ? json['accessorySlot']?.toString()
          : null,
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

  /// İsim efekti — sitedeki `cssPreset` stili (renk/geçiş/parlama/kontur/ışıltı).
  final CosmeticNameStyle? nameStyle;

  /// Giriş efekti medya türü (lottie/svga/gif/video/image) ve süresi.
  final String? assetType;
  final int? durationMs;

  /// Avatar aksesuarı konumu: hat / crown / glasses / wings / mask / other.
  final String? accessorySlot;

  /// Görsel tabanlı kozmetik mi (çerçeve/balon/mikrofon/aksesuar/giriş görseli)?
  String? get imageUrl {
    final a = (assetUrl ?? previewUrl)?.trim();
    return (a == null || a.isEmpty) ? null : a;
  }

  bool isUnlockedFor({
    required VipTier tier,
    String? role,
  }) {
    if (!active) return false;
    if (!tier.isAtLeast(requiredTier)) return false;
    final req = requiredRole?.trim().toLowerCase();
    if (req != null && req.isNotEmpty) {
      final r = role?.trim().toLowerCase() ?? '';
      if (r != req && !r.contains(req)) return false;
    }
    return true;
  }

  @override
  List<Object?> get props =>
      [id, slot, name, effectKind, previewUrl, requiredTier, active, nameStyle];
}

class ColorSpec extends Equatable {
  const ColorSpec(this.hex);
  final String hex;
  @override
  List<Object?> get props => [hex];
}
