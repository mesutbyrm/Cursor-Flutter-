import '../../../core/util/json_util.dart';

/// Admin katalog satırı — `/api/admin/gifts` (pasifler dahil).
/// CreateGiftTypeDto / UpdateGiftTypeDto alanlarını kapsar.
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
    this.animationType = 'lottie',
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
  });

  factory AdminGiftType.fromJson(Map<String, dynamic> json) {
    return AdminGiftType(
      id: (pick(json, ['id', 'giftTypeId', 'slug']) ?? '').toString(),
      name: (pick(json, ['name', 'nameTr']) ?? '').toString(),
      nameEn: (pick(json, ['nameEn']) ?? '').toString(),
      price: asInt(pick(json, ['price'])),
      icon: pick(json, ['icon'])?.toString(),
      imageUrl: pick(json, [
        'imageUrl',
        'imageCloudPath',
        'assetUrl',
        'assetCloudPath',
      ])?.toString(),
      thumbnailUrl: pick(json, ['thumbnailUrl', 'thumbnail', 'thumbnailCloudPath'])
          ?.toString(),
      animationUrl: pick(json, [
        'animationUrl',
        'animation',
        'animationCloudPath',
      ])?.toString(),
      animationType:
          (pick(json, ['animationType', 'animationKind']) ?? 'lottie').toString(),
      soundUrl: pick(json, ['soundUrl', 'sound', 'soundCloudPath'])?.toString(),
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
}

/// Desteklenen animasyon türleri (admin yükleme).
abstract final class AdminGiftAnimationTypes {
  static const all = [
    ('lottie', 'Lottie (.json)'),
    ('rive', 'Rive (.riv)'),
    ('svga', 'SVGA (.svga)'),
    ('mp4', 'MP4 video'),
    ('webm', 'WebM video'),
    ('gif', 'GIF'),
    ('none', 'Animasyon yok'),
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
