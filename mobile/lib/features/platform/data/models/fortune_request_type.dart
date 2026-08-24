import 'package:canlifal_social/core/images/canlifal_image_urls.dart';
import 'package:canlifal_social/core/util/json_util.dart';

import '../../../../core/util/fortune_price_parser.dart';

/// `GET /api/fortune-request-types` — fal türü kaydı.
class FortuneRequestType {
  const FortuneRequestType({
    required this.key,
    required this.label,
    this.jetonCost,
    this.imageUrl,
    this.description,
    this.sortOrder = 0,
    this.isActive = true,
    this.raw = const {},
  });

  final String key;
  final String label;
  final int? jetonCost;
  final String? imageUrl;
  final String? description;
  final int sortOrder;
  final bool isActive;
  final Map<String, dynamic> raw;

  factory FortuneRequestType.fromJson(Map<String, dynamic> json) {
    final key = pick(json, ['key', 'slug', 'id', 'type', 'fortuneType'])
            ?.toString()
            .trim() ??
        '';
    final label = pick(json, ['label', 'name', 'title', 'nameTr'])
        ?.toString()
        .trim();
    final iconRaw = pick(json, [
      'icon',
      'image',
      'imageUrl',
      'thumbnail',
      'iconUrl',
    ])?.toString()
        .trim();
    String? imageUrl;
    if (iconRaw != null && iconRaw.isNotEmpty) {
      if (iconRaw.startsWith('http') || iconRaw.startsWith('/')) {
        imageUrl = CanlifalImageUrls.resolve(iconRaw);
      }
    }
    final description =
        pick(json, ['description', 'descTr', 'desc', 'subtitle'])
            ?.toString()
            .trim();
    return FortuneRequestType(
      key: key.isEmpty ? 'general' : key,
      label: label != null && label.isNotEmpty ? label : key,
      jetonCost: parseFortuneJetonPrice(json),
      imageUrl: imageUrl,
      description:
          description != null && description.isNotEmpty ? description : null,
      sortOrder: asInt(pick(json, ['sortOrder', 'order', 'position'])),
      isActive: json['isActive'] != false,
      raw: json,
    );
  }
}
