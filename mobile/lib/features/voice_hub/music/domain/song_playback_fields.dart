import '../../domain/entities/chat_room_dj_state.dart';
import '../../data/services/voice_room_music_pipeline_log.dart';

/// Backend JSON alanlarını web ile aynı sırayla çözer.
///
/// Öncelik: `musicUrl` → `videoUrl` → `youtubeUrl` → `videoId`
final class SongPlaybackFields {
  static const _urlKeys = ['musicUrl', 'videoUrl', 'youtubeUrl'];

  static SongPlaybackFields fromJson(Map<String, dynamic> json) {
    final fields = _parse(json, log: true);
    return fields;
  }

  /// Tekrarlayan getter çağrılarında log spam önleme.
  static SongPlaybackFields parseQuiet(Map<String, dynamic> json) =>
      _parse(json, log: false);

  static SongPlaybackFields _parse(Map<String, dynamic> json, {required bool log}) {
    final fields = SongPlaybackFields._(
      musicUrl: _firstNonEmpty(json, _urlKeys),
      videoUrl: json['videoUrl']?.toString().trim(),
      audioUrl: json['audioUrl']?.toString().trim(),
      streamUrl: json['streamUrl']?.toString().trim(),
      youtubeUrl: json['youtubeUrl']?.toString().trim(),
      videoId: _resolveVideoId(json),
      title: json['title']?.toString(),
      thumbnail: json['thumbnail']?.toString() ?? json['thumbUrl']?.toString(),
      duration: json['duration']?.toString(),
      playMode: _resolvePlayMode(json),
      isVideoRequest: _isVideoRequest(json),
    );
    if (log) {
      VoiceRoomMusicPipelineLog.songEvent(
        event: 'parse',
        receivedJson: json,
        parsedVideoId: fields.videoId,
        parsedMusicUrl: fields.resolvedStreamUrl,
      );
    }
    return fields;
  }

  const SongPlaybackFields._({
    this.musicUrl,
    this.videoUrl,
    this.audioUrl,
    this.streamUrl,
    this.youtubeUrl,
    this.videoId,
    this.title,
    this.thumbnail,
    this.duration,
    this.playMode,
    required this.isVideoRequest,
  });

  final String? musicUrl;
  final String? videoUrl;
  final String? audioUrl;
  final String? streamUrl;
  final String? youtubeUrl;
  final String? videoId;
  final String? title;
  final String? thumbnail;
  final String? duration;
  final String? playMode;
  final bool isVideoRequest;

  bool get hasPlayableSource =>
      resolvedStreamUrl != null || (videoId != null && videoId!.isNotEmpty);

  /// Sesli oda — doğrudan oynatılabilir audio stream (YouTube watch sayfası değil).
  String? get resolvedAudioStreamUrl {
    for (final raw in [musicUrl, audioUrl, streamUrl]) {
      final normalized = _normalizePlayableMediaUrl(raw);
      if (normalized != null) return normalized;
    }
    return null;
  }

  /// Canlı yayın — video player için gerçek medya URL'si.
  String? get resolvedVideoStreamUrl {
    for (final raw in [videoUrl, streamUrl, musicUrl]) {
      final normalized = _normalizePlayableMediaUrl(raw);
      if (normalized != null) return normalized;
    }
    return null;
  }

  /// Oynatılabilir URL — sırayla dene, hiçbiri yoksa videoId'den watch URL.
  String? get resolvedStreamUrl {
    for (final key in _urlKeys) {
      final raw = switch (key) {
        'musicUrl' => musicUrl,
        'videoUrl' => videoUrl,
        'youtubeUrl' => youtubeUrl,
        _ => null,
      };
      final normalized = _normalizeUrl(raw);
      if (normalized != null) return normalized;
    }
    final id = videoId?.trim();
    if (id != null && id.isNotEmpty) {
      return 'https://www.youtube.com/watch?v=$id';
    }
    return null;
  }

  static String? _firstNonEmpty(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final raw = json[key]?.toString().trim();
      if (raw != null && raw.isNotEmpty) return raw;
    }
    return null;
  }

  static String? _normalizeUrl(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http') || trimmed.startsWith('/')) return trimmed;
    final id = ChatRoomDjState.videoIdFromLoose(trimmed);
    if (id != null && id.isNotEmpty) {
      return 'https://www.youtube.com/watch?v=$id';
    }
    return trimmed;
  }

  /// YouTube watch/embed sayfası değil — gerçek medya stream'i.
  static String? _normalizePlayableMediaUrl(String? raw) {
    final normalized = _normalizeUrl(raw);
    if (normalized == null) return null;
    final lower = normalized.toLowerCase();
    if (lower.contains('youtube.com/watch') ||
        lower.contains('youtu.be/') ||
        lower.contains('youtube.com/embed')) {
      return null;
    }
    if (!normalized.startsWith('http') && !normalized.startsWith('/')) {
      return null;
    }
    return normalized;
  }

  static String? _resolveVideoId(Map<String, dynamic> json) {
    final direct = json['videoId']?.toString().trim();
    if (direct != null && direct.isNotEmpty) return direct;
    for (final key in _urlKeys) {
      final raw = json[key]?.toString();
      if (raw == null) continue;
      final fromUrl = ChatRoomDjState.videoIdFromLoose(raw);
      if (fromUrl != null && fromUrl.isNotEmpty) return fromUrl;
    }
    return null;
  }

  static String? _resolvePlayMode(Map<String, dynamic> json) {
    final raw = json['playMode']?.toString().trim().toLowerCase();
    if (raw == 'audio' || raw == 'video') return raw;
    final requestType = json['requestType']?.toString().trim().toLowerCase();
    if (requestType == 'audio' || requestType == 'video') return requestType;
    return raw;
  }

  static bool _isVideoRequest(Map<String, dynamic> json) {
    final mode = _resolvePlayMode(json);
    if (mode == 'video') return true;
    if (mode == 'audio') return false;
    return json['withVideo'] == true ||
        json['playWithVideo'] == true ||
        json['isVideo'] == true ||
        json['videoMode']?.toString().toLowerCase() == 'video';
  }
}
