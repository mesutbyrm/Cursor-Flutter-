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

enum VoiceSseMusicSignal { started, stopped, update, none }

/// Üretim SSE — `music_started` / `music_stopped` (web ile aynı).
VoiceSseMusicSignal voiceSseMusicSignal(Map<String, dynamic> payload) {
  final t = (payload['type'] ??
          payload['event'] ??
          payload['eventName'] ??
          payload['action'] ??
          '')
      .toString()
      .toLowerCase()
      .trim();
  if (t == 'music_started' ||
      t == 'musicstarted' ||
      t == 'music_start') {
    return VoiceSseMusicSignal.started;
  }
  if (t == 'music_stopped' ||
      t == 'musicstopped' ||
      t == 'music_stop') {
    return VoiceSseMusicSignal.stopped;
  }
  if (payload['playing'] == false &&
      payload['musicUrl'] == null &&
      payload['nowPlaying'] == null &&
      (payload['isPlaying'] == false || payload['isPlaying'] == null)) {
    return VoiceSseMusicSignal.stopped;
  }
  if (voiceSseDjIsPlaying(payload) ||
      payload['musicUrl'] != null ||
      payload['nowPlaying'] != null) {
    return VoiceSseMusicSignal.update;
  }
  return VoiceSseMusicSignal.none;
}

int? voiceSseLikeCount(Map<String, dynamic> payload) {
  final raw = payload['likeCount'] ??
      payload['likes'] ??
      payload['like_count'] ??
      (payload['nowPlaying'] is Map
          ? (payload['nowPlaying'] as Map)['likeCount']
          : null);
  if (raw is num) return raw.toInt();
  return int.tryParse(raw?.toString() ?? '');
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
