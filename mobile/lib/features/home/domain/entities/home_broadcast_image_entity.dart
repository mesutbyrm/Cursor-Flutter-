import '../../../../core/util/json_util.dart';

/// `GET /api/broadcast-images` görsel satırı.
class HomeBroadcastImageEntity {
  const HomeBroadcastImageEntity({
    required this.id,
    required this.imageUrl,
    this.title,
    this.category,
  });

  factory HomeBroadcastImageEntity.fromJson(Map<String, dynamic> json) {
    final url = pick(json, [
      'imageUrl',
      'image',
      'url',
      'src',
      'thumbnail',
      'cover',
    ])?.toString();
    return HomeBroadcastImageEntity(
      id: pick(json, ['id', '_id'])?.toString() ??
          (url ?? 'img').hashCode.toString(),
      imageUrl: url ?? '',
      title: pick(json, ['title', 'name', 'label'])?.toString(),
      category: pick(json, ['category', 'type', 'tag'])?.toString(),
    );
  }

  final String id;
  final String imageUrl;
  final String? title;
  final String? category;

  bool get isValid => imageUrl.trim().isNotEmpty;
}
