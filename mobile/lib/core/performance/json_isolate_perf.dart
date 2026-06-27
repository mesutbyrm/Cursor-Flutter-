import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Görev 9 — büyük JSON parse işlemleri UI thread dışında (isolate).
///
/// Dio [FusedTransformer] ile aynı eşik (~50 KB). Küçük yanıtlar senkron,
/// büyük yanıtlar `compute` ile ayrı isolate'te decode edilir.
abstract final class JsonIsolatePerf {
  /// Flutter asset bundle / Dio varsayılan eşiği.
  static const largeThreshold = 50 * 1024;

  static bool shouldIsolate(String raw) => raw.length >= largeThreshold;

  static bool shouldIsolateBytes(List<int> bytes) =>
      bytes.length >= largeThreshold;

  /// JSON string → dynamic. Büyük gövdeler isolate'te parse edilir.
  static Future<dynamic> decode(String raw) async {
    if (!shouldIsolate(raw)) return jsonDecode(raw);
    return compute(_decodeJson, raw);
  }

  static Future<Map<String, dynamic>?> decodeMap(String raw) async {
    final value = await decode(raw);
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static Future<List<dynamic>?> decodeList(String raw) async {
    final value = await decode(raw);
    if (value is List) return value;
    return null;
  }

  /// UTF-8 baytlarından JSON — disk cache / stream birleştirme.
  static Future<dynamic> decodeUtf8(List<int> bytes) async {
    if (!shouldIsolateBytes(bytes)) {
      return jsonDecode(utf8.decode(bytes, allowMalformed: true));
    }
    return compute(_decodeUtf8Json, bytes);
  }
}

dynamic _decodeJson(String raw) => jsonDecode(raw);

dynamic _decodeUtf8Json(List<int> bytes) =>
    jsonDecode(utf8.decode(bytes, allowMalformed: true));
