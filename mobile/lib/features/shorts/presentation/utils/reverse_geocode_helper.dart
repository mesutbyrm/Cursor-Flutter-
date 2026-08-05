import 'package:dio/dio.dart';

/// GPS koordinatından okunabilir konum etiketi (OSM Nominatim).
Future<String> reverseGeocodeLabel(double lat, double lng) async {
  try {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {'User-Agent': 'CanlifalMobile/1.0'},
      ),
    );
    final res = await dio.get<Map<String, dynamic>>(
      'https://nominatim.openstreetmap.org/reverse',
      queryParameters: {
        'lat': lat,
        'lon': lng,
        'format': 'json',
        'accept-language': 'tr',
        'zoom': 14,
      },
    );
    final data = res.data;
    if (data == null) return _coordLabel(lat, lng);
    final address = data['address'];
    if (address is Map) {
      final m = Map<String, dynamic>.from(address);
      for (final key in [
        'city',
        'town',
        'village',
        'suburb',
        'county',
        'state',
      ]) {
        final v = m[key]?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
    }
    final display = data['display_name']?.toString();
    if (display != null && display.isNotEmpty) {
      final first = display.split(',').first.trim();
      if (first.isNotEmpty) return first;
    }
    return _coordLabel(lat, lng);
  } catch (_) {
    return _coordLabel(lat, lng);
  }
}

String _coordLabel(double lat, double lng) =>
    '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
