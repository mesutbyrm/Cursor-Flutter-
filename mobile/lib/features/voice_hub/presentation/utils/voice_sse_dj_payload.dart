/// SSE `dj` / `music` / `song` gövdesini düzleştirir (`data`, `payload`, `dj` sarmalayıcıları).
Map<String, dynamic> unwrapVoiceSseDjPayload(Map<String, dynamic> raw) {
  var map = Map<String, dynamic>.from(raw);
  for (var depth = 0; depth < 3; depth++) {
    final nested = map['data'] ?? map['payload'] ?? map['dj'];
    if (nested is! Map) break;
    final inner = Map<String, dynamic>.from(nested);
    map = {...map, ...inner};
  }
  return map;
}

/// Sunucu `playing` / `isPlaying` bayraklarını birleştirir.
bool voiceSseDjIsPlaying(Map<String, dynamic> payload) {
  return payload['playing'] == true || payload['isPlaying'] == true;
}

/// `startedAt` ISO veya epoch ms → playback sync için ms.
int? voiceSseTrackStartedAtMs(dynamic raw) {
  if (raw is num) return raw.round();
  if (raw is String && raw.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(raw.trim());
    if (parsed != null) return parsed.millisecondsSinceEpoch;
    final asInt = int.tryParse(raw);
    if (asInt != null) return asInt;
  }
  return null;
}
