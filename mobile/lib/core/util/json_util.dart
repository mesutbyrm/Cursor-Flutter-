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
