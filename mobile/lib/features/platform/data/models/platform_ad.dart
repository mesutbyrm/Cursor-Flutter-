import '../../../../core/util/json_util.dart';

/// `GET /api/ads/active` — aktif reklam yerleşimi.
class PlatformAd {
  const PlatformAd({
    required this.id,
    this.placement,
    this.type,
    this.provider,
    this.unitId,
    this.raw = const {},
  });

  final String id;
  final String? placement;
  final String? type;
  final String? provider;
  final String? unitId;
  final Map<String, dynamic> raw;

  factory PlatformAd.fromJson(Map<String, dynamic> json) {
    return PlatformAd(
      id: pick(json, ['id', '_id', 'adId'])?.toString() ?? '',
      placement: pick(json, ['placement', 'slot', 'position'])?.toString(),
      type: pick(json, ['type', 'format'])?.toString(),
      provider: pick(json, ['provider', 'network'])?.toString(),
      unitId: pick(json, ['unitId', 'adUnitId', 'unit'])?.toString(),
      raw: json,
    );
  }
}
