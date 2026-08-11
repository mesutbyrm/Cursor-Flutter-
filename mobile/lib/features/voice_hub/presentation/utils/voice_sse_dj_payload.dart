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

String _sseEventType(Map<String, dynamic> payload) =>
    (payload['type'] ??
            payload['event'] ??
            payload['eventName'] ??
            payload['action'] ??
            '')
        .toString()
        .toLowerCase()
        .trim();

/// `song_started` vb. SSE → DJ oynatıcı payload'ına normalize eder.
Map<String, dynamic> normalizeSongSseForDjPlayback(Map<String, dynamic> raw) {
  final map = unwrapVoiceSseDjPayload(raw);
  final type = _sseEventType(map);

  if (type == 'song_started' ||
      type == 'song_resumed' ||
      type == 'music_started' ||
      type == 'musicstarted') {
    map['playing'] = true;
    map['isPlaying'] = true;
  }

  if (map['nowPlaying'] == null) {
    for (final key in const ['currentSong', 'current', 'song']) {
      final node = map[key];
      if (node is Map) {
        map['nowPlaying'] = Map<String, dynamic>.from(node);
        break;
      }
    }
  }

  final np = map['nowPlaying'];
  if (np is Map) {
    final song = Map<String, dynamic>.from(np);
    if (map['musicUrl'] == null && song['musicUrl'] != null) {
      map['musicUrl'] = song['musicUrl'];
    }
    if (map['videoId'] == null && song['videoId'] != null) {
      map['videoId'] = song['videoId'];
    }
    if (map['currentVideoId'] == null && song['videoId'] != null) {
      map['currentVideoId'] = song['videoId'];
    }
  }

  return map;
}

bool shouldApplyDjPlaybackFromSongSse(Map<String, dynamic> raw) {
  final type = _sseEventType(raw);
  return const {
    'song_started',
    'song_resumed',
    'song_changed',
    'queue_updated',
    'music_started',
    'musicstarted',
    'player_state',
    'dj',
    'dj_update',
  }.contains(type);
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
      t == 'music_start' ||
      t == 'song_started' ||
      t == 'song_resumed') {
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
