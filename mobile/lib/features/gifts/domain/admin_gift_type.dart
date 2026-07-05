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
    this.thumbnailUrl,
    this.category,
    this.tier,
    this.sortOrder = 0,
    this.isActive = true,
    this.isHidden = false,
    this.isFeatured = false,
    this.isPopular = false,
    this.isNew = false,
    this.isFullscreen = false,
  });

  factory AdminGiftType.fromJson(Map<String, dynamic> json) {
    return AdminGiftType(
      id: (pick(json, ['id', 'giftTypeId', 'slug']) ?? '').toString(),
      name: (pick(json, ['name', 'nameTr']) ?? '').toString(),
      nameEn: (pick(json, ['nameEn']) ?? '').toString(),
      price: asInt(pick(json, ['price'])),
      icon: pick(json, ['icon'])?.toString(),
      thumbnailUrl: pick(json, ['thumbnailUrl', 'thumbnail', 'iconUrl', 'image'])
          ?.toString(),
      category: pick(json, ['category'])?.toString(),
      tier: pick(json, ['tier'])?.toString(),
      sortOrder: asInt(pick(json, ['sortOrder'])),
      isActive: pick(json, ['isActive']) != false,
      isHidden: pick(json, ['isHidden']) == true,
      isFeatured: pick(json, ['isFeatured']) == true,
      isPopular: pick(json, ['isPopular']) == true,
      isNew: pick(json, ['isNew']) == true,
      isFullscreen: pick(json, ['isFullscreen']) == true,
    );
  }

  final String id;
  final String name;
  final String nameEn;
  final int price;
  final String? icon;
  final String? thumbnailUrl;
  final String? category;
  final String? tier;
  final int sortOrder;
  final bool isActive;
  final bool isHidden;
  final bool isFeatured;
  final bool isPopular;
  final bool isNew;
  final bool isFullscreen;
}
