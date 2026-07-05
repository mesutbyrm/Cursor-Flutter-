import '../../../core/util/json_util.dart';

/// Gönderen haritası noktası — şehir/ülke bazlı hediye yoğunluğu.
class GiftMapPoint {
  const GiftMapPoint({
    required this.label,
    this.city,
    this.country,
    this.total = 0,
    this.count = 0,
    this.lat,
    this.lng,
  });

  factory GiftMapPoint.fromJson(Map<String, dynamic> json) {
    final city = pick(json, ['city'])?.toString();
    final country = pick(json, ['country'])?.toString();
    final label = [city, country]
        .where((e) => e != null && e.trim().isNotEmpty)
        .join(', ');
    return GiftMapPoint(
      label: label.isNotEmpty
          ? label
          : (pick(json, ['label', 'name', 'region']) ?? '—').toString(),
      city: city,
      country: country,
      total: asInt(pick(json, ['total', 'coins', 'amount', 'value'])),
      count: asInt(pick(json, ['count', 'gifts', 'giftCount'])),
      lat: _toDouble(pick(json, ['lat', 'latitude'])),
      lng: _toDouble(pick(json, ['lng', 'lon', 'longitude'])),
    );
  }

  final String label;
  final String? city;
  final String? country;
  final int total;
  final int count;
  final double? lat;
  final double? lng;

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }
}

/// Gönderen haritası — `/api/gifts/insights/map`.
class GiftSenderMap {
  const GiftSenderMap({
    this.scope = 'tr',
    this.period = 'weekly',
    this.points = const [],
  });

  factory GiftSenderMap.fromJson(Map<String, dynamic> json) {
    final raw = pick(json, ['points', 'items', 'data']);
    final points = <GiftMapPoint>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) points.add(GiftMapPoint.fromJson(asJsonMap(e)));
      }
    }
    points.sort((a, b) => b.total.compareTo(a.total));
    return GiftSenderMap(
      scope: (pick(json, ['scope']) ?? 'tr').toString(),
      period: (pick(json, ['period']) ?? 'weekly').toString(),
      points: points,
    );
  }

  final String scope;
  final String period;
  final List<GiftMapPoint> points;

  int get maxTotal =>
      points.isEmpty ? 0 : points.map((p) => p.total).reduce((a, b) => a > b ? a : b);
}

/// Bana özel hediye önerisi — `/api/gifts/insights/me/recommendations`.
class GiftRecommendation {
  const GiftRecommendation({
    required this.giftId,
    required this.name,
    this.iconUrl,
    this.price = 0,
    this.reason,
  });

  factory GiftRecommendation.fromJson(Map<String, dynamic> json) {
    return GiftRecommendation(
      giftId: (pick(json, ['giftId', 'giftTypeId', 'id', 'slug']) ?? '')
          .toString(),
      name: (pick(json, ['name', 'nameTr', 'label']) ?? '').toString(),
      iconUrl: pick(json, ['icon', 'iconUrl', 'image'])?.toString(),
      price: asInt(pick(json, ['price', 'coins', 'amount'])),
      reason: pick(json, ['reason', 'why', 'note'])?.toString(),
    );
  }

  final String giftId;
  final String name;
  final String? iconUrl;
  final int price;
  final String? reason;
}
