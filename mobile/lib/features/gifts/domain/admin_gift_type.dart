import '../../../core/config/env.dart';
import '../../../core/util/json_util.dart';

/// Admin katalog satırı — `GET /api/admin/gifts` (`gift_types` şeması).
class AdminGiftType {
  const AdminGiftType({
    required this.id,
    required this.name,
    this.nameEn = '',
    this.price = 0,
    this.icon,
    this.imageUrl,
    this.thumbnailUrl,
    this.animationUrl,
    this.animationType = 'image',
    this.soundUrl,
    this.animationDurationMs = 0,
    this.effectColor,
    this.category,
    this.tier,
    this.sortOrder = 0,
    this.isActive = true,
    this.isHidden = false,
    this.isFeatured = false,
    this.isPopular = false,
    this.isNew = false,
    this.isFullscreen = false,
    this.isPremium = false,
    this.comboEnabled = false,
    this.isLucky = false,
    this.iconImageCloudPath,
    this.cloudStoragePath,
    this.thumbnailCloudPath,
    this.soundCloudPath,
  });

  factory AdminGiftType.fromJson(
    Map<String, dynamic> json, {
    String? siteOrigin,
  }) {
    final origin = siteOrigin ?? Env.siteOrigin;
    return AdminGiftType(
      id: (pick(json, ['id', 'giftTypeId', 'slug']) ?? '').toString(),
      name: (pick(json, ['name', 'nameTr']) ?? '').toString(),
      nameEn: (pick(json, ['nameEn']) ?? '').toString(),
      price: asInt(pick(json, ['price'])),
      icon: pick(json, ['icon'])?.toString(),
      imageUrl: _resolveAdminMediaUrl(
        pick(json, ['iconImageUrl', 'imageUrl'])?.toString(),
        origin,
      ),
      thumbnailUrl: _resolveAdminMediaUrl(
        pick(json, ['thumbnailUrl', 'thumbnail'])?.toString(),
        origin,
      ),
      animationUrl: _resolveAdminMediaUrl(
        pick(json, ['assetUrl', 'animationUrl'])?.toString(),
        origin,
      ),
      animationType: (pick(json, ['assetType', 'animationType', 'animation']) ??
              'image')
          .toString(),
      soundUrl: _resolveAdminMediaUrl(
        pick(json, ['soundUrl', 'sound'])?.toString(),
        origin,
      ),
      animationDurationMs:
          asInt(pick(json, ['animationDurationMs', 'animationDuration'])),
      effectColor: pick(json, ['effectColor', 'glowColor'])?.toString(),
      category: pick(json, ['category'])?.toString(),
      tier: pick(json, ['tier', 'rarity'])?.toString(),
      sortOrder: asInt(pick(json, ['sortOrder'])),
      isActive: pick(json, ['isActive', 'enabled']) != false,
      isHidden: pick(json, ['isHidden']) == true,
      isFeatured: pick(json, ['isFeatured']) == true,
      isPopular: pick(json, ['isPopular']) == true,
      isNew: pick(json, ['isNew']) == true,
      isFullscreen: pick(json, ['isFullscreen']) == true,
      isPremium: pick(json, ['isPremium', 'premium']) == true,
      comboEnabled: pick(json, ['comboEnabled', 'supportsCombo']) == true,
      isLucky: json['isLucky'] == true,
      iconImageCloudPath:
          pick(json, ['iconImageCloudPath', 'imageCloudPath'])?.toString(),
      cloudStoragePath: pick(json, [
        'cloudStoragePath',
        'animationCloudPath',
      ])?.toString(),
      thumbnailCloudPath: pick(json, ['thumbnailCloudPath'])?.toString(),
      soundCloudPath: pick(json, ['soundCloudPath'])?.toString(),
    );
  }

  final String id;
  final String name;
  final String nameEn;
  final int price;
  final String? icon;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? animationUrl;
  final String animationType;
  final String? soundUrl;
  final int animationDurationMs;
  final String? effectColor;
  final String? category;
  final String? tier;
  final int sortOrder;
  final bool isActive;
  final bool isHidden;
  final bool isFeatured;
  final bool isPopular;
  final bool isNew;
  final bool isFullscreen;
  final bool isPremium;
  final bool comboEnabled;
  final bool isLucky;
  final String? iconImageCloudPath;
  final String? cloudStoragePath;
  final String? thumbnailCloudPath;
  final String? soundCloudPath;

  bool get hasVideoAnimation {
    final t = animationType.toLowerCase().trim();
    if (t == 'video') return true;
    final url = animationUrl?.toLowerCase().split('?').first ?? '';
    return url.endsWith('.mp4') || url.endsWith('.webm');
  }
}

String? _resolveAdminMediaUrl(String? raw, String siteOrigin) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('http')) return raw;
  final origin = siteOrigin.trim().replaceAll(RegExp(r'/+$'), '');
  if (origin.isEmpty) return raw;
  return raw.startsWith('/') ? '$origin$raw' : '$origin/$raw';
}

/// Desteklenen `assetType` değerleri — `gift_types.assetType`.
abstract final class AdminGiftAnimationTypes {
  static const all = [
    ('image', 'Statik görsel'),
    ('lottie', 'Lottie (.json)'),
    ('svga', 'SVGA (.svga)'),
    ('video', 'MP4 / WebM video'),
    ('gif', 'GIF'),
  ];
}

/// Kategori ve kademe önerileri.
abstract final class AdminGiftPresets {
  static const categories = [
    'luxury',
    'classic',
    'fun',
    'seasonal',
    'pk',
    'vip',
    'romantic',
  ];

  static const tiers = [
    'common',
    'rare',
    'epic',
    'legendary',
    'mythic',
    'elmas',
    'altin',
  ];
}
