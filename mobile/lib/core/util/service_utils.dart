import '../core/util/json_util.dart';

/// Servis katmanı ortak JSON yardımcıları.
abstract final class ServiceUtils {
  static Map<String, dynamic>? unwrapMap(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['success'] == true && body['data'] != null) {
        final data = body['data'];
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
      }
      return body;
    }
    if (body is Map) return Map<String, dynamic>.from(body);
    return null;
  }

  static List<Map<String, dynamic>> extractList(
    dynamic body, {
    List<String> keys = const ['items', 'data'],
  }) {
    if (body is List) return asJsonList(body);
    final map = unwrapMap(body) ?? (body is Map ? asJsonMap(body) : null);
    if (map != null) {
      for (final key in keys) {
        final raw = map[key];
        if (raw is List) return asJsonList(raw);
      }
    }
    return const [];
  }
}
