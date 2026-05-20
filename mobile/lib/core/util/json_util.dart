Map<String, dynamic> asJsonMap(dynamic v) {
  if (v is Map<String, dynamic>) return v;
  if (v is Map) return Map<String, dynamic>.from(v);
  return {};
}

List<Map<String, dynamic>> asJsonList(dynamic v) {
  if (v is! List) return const [];
  return v.map((e) => asJsonMap(e)).toList();
}

dynamic pick(Map<String, dynamic> json, List<String> keys) {
  for (final k in keys) {
    if (json.containsKey(k) && json[k] != null) return json[k];
  }
  return null;
}

int asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse(v.toString()) ?? 0;
}

bool asBool(dynamic v) => v == true || v == 1 || v == 'true';

/// API bazen `{name, image}` gibi nesne döner; ekranda ham Map metni göstermeyin.
String? jsonDisplayLabel(
  dynamic value, {
  List<String> keys = const [
    'name',
    'displayName',
    'username',
    'nameTr',
    'title',
    'label',
  ],
}) {
  if (value == null) return null;
  if (value is String) {
    final s = value.trim();
    if (s.isEmpty || s.startsWith('{') || s.contains('image:')) return null;
    if (s.length > 80) return null;
    return s;
  }
  if (value is Map) {
    final m = asJsonMap(value);
    for (final k in keys) {
      final label = jsonDisplayLabel(m[k], keys: keys);
      if (label != null) return label;
    }
  }
  return null;
}

String jsonDisplayLabelOr(dynamic value, String fallback) =>
    jsonDisplayLabel(value) ?? fallback;
