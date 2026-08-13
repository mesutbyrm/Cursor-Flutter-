import '../../../../core/util/json_util.dart';

/// `GET /api/online-fal` bölüm satırı.
class HomeOnlineFalEntity {
  const HomeOnlineFalEntity({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.route,
  });

  factory HomeOnlineFalEntity.fromJson(Map<String, dynamic> json) {
    final title = pick(json, ['title', 'name', 'label'])?.toString() ?? '';
    final route =
        pick(json, ['route', 'link', 'href', 'url', 'path'])?.toString();
    return HomeOnlineFalEntity(
      id: pick(json, ['id', '_id', 'slug'])?.toString() ??
          (title.isNotEmpty ? title : 'section').hashCode.toString(),
      title: title,
      subtitle: pick(json, ['subtitle', 'description', 'summary'])?.toString(),
      imageUrl: pick(json, ['imageUrl', 'image', 'cover', 'icon'])?.toString(),
      route: route,
    );
  }

  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? route;

  bool get isValid => title.trim().isNotEmpty;
}
