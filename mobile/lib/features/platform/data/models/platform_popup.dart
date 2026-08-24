import '../../../../core/util/json_util.dart';

/// `GET /api/popups` — site geneli popup bildirimi.
class PlatformPopup {
  const PlatformPopup({
    required this.id,
    required this.title,
    this.message,
    this.imageUrl,
    this.actionUrl,
    this.actionLabel,
    this.type,
    this.raw = const {},
  });

  final String id;
  final String title;
  final String? message;
  final String? imageUrl;
  final String? actionUrl;
  final String? actionLabel;
  final String? type;
  final Map<String, dynamic> raw;

  factory PlatformPopup.fromJson(Map<String, dynamic> json) {
    final id = pick(json, ['id', '_id', 'popupId'])?.toString() ?? '';
    return PlatformPopup(
      id: id,
      title: pick(json, ['title', 'name', 'heading'])?.toString() ?? 'Bildirim',
      message: pick(json, ['message', 'body', 'content', 'description'])
          ?.toString(),
      imageUrl: pick(json, ['imageUrl', 'image', 'thumbnail', 'banner'])
          ?.toString(),
      actionUrl: pick(json, ['actionUrl', 'url', 'link', 'href'])?.toString(),
      actionLabel:
          pick(json, ['actionLabel', 'buttonText', 'cta'])?.toString(),
      type: pick(json, ['type', 'kind'])?.toString(),
      raw: json,
    );
  }
}
