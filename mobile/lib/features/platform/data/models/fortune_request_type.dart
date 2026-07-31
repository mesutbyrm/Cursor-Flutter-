import '../../../../core/util/json_util.dart';

/// `GET /api/fortune-request-types` — canlı fal türü.
class FortuneRequestType {
  const FortuneRequestType({
    required this.key,
    required this.label,
    this.jetonCost,
    this.raw = const {},
  });

  final String key;
  final String label;
  final int? jetonCost;
  final Map<String, dynamic> raw;

  factory FortuneRequestType.fromJson(Map<String, dynamic> json) {
    final key = pick(json, ['key', 'slug', 'id', 'type', 'fortuneType'])
            ?.toString()
            .trim() ??
        '';
    final label = pick(json, ['label', 'name', 'title'])?.toString().trim();
    return FortuneRequestType(
      key: key.isEmpty ? 'general' : key,
      label: label != null && label.isNotEmpty ? label : key,
      jetonCost: asInt(pick(json, ['jetonCost', 'cost', 'price'])),
      raw: json,
    );
  }
}
