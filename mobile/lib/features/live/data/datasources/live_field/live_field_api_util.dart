import '../../../../../core/network/api_exception.dart';
import '../../../../../core/util/json_util.dart';

/// `/api/live/*` yanıt sarmalayıcısı — `{ success, data }`.
class LiveFieldApiUtil {
  LiveFieldApiUtil._();

  static Map<String, dynamic>? unwrapData(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['success'] == false) {
        throw parseError(body);
      }
      if (body['success'] == true && body['data'] is Map) {
        return asJsonMap(body['data']);
      }
      return body;
    }
    if (body is Map) {
      final m = Map<String, dynamic>.from(body);
      if (m['success'] == false) {
        throw parseError(m);
      }
      if (m['success'] == true && m['data'] is Map) {
        return asJsonMap(m['data']);
      }
      return m;
    }
    return null;
  }

  static List<Map<String, dynamic>> listFromData(
    dynamic body, {
    String listKey = 'rooms',
  }) {
    final map = unwrapData(body);
    if (map == null) return const [];
    final raw = map[listKey] ?? map['items'] ?? map['messages'] ?? map['users'];
    if (raw is List) return asJsonList(raw);
    return const [];
  }

  static ApiException parseError(Map<String, dynamic> body) {
    final err = body['error'];
    if (err is Map) {
      final code = err['code']?.toString();
      final message = err['message']?.toString() ??
          body['message']?.toString() ??
          'İstek başarısız';
      return ApiException(message, errorCode: code);
    }
    return ApiException(
      (body['message'] ?? body['error'] ?? 'İstek başarısız').toString(),
    );
  }
}
