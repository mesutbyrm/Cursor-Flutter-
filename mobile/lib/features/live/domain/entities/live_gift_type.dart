import '../../../../core/util/json_util.dart';

/// `/api/video-streams/gifts` satırı (site ile aynı hediye türleri).
class LiveVideoGiftType {
  LiveVideoGiftType({
    required this.id,
    required this.name,
    required this.price,
    this.iconPath,
  });

  factory LiveVideoGiftType.fromJson(Map<String, dynamic> json) {
    return LiveVideoGiftType(
      id: pick(json, ['id'])?.toString() ?? '',
      name: (pick(json, ['name', 'nameEn']) ?? '').toString(),
      price: asInt(pick(json, ['price'])),
      iconPath: pick(json, ['icon']) as String?,
    );
  }

  final String id;
  final String name;
  final int price;
  final String? iconPath;

  String iconUrl(String siteOrigin) {
    final p = iconPath;
    if (p == null || p.isEmpty) return '';
    if (p.startsWith('http')) return p;
    final o = siteOrigin.trim().replaceAll(RegExp(r'/+$'), '');
    return p.startsWith('/') ? '$o$p' : '$o/$p';
  }
}
