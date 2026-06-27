import '../../domain/entities/chat_room_dj_state.dart';

/// YouTube video kimliği doğrulama — akış URL'lerini video moduna sokma.
abstract final class YoutubeVideoId {
  static final _idPattern = RegExp(r'^[a-zA-Z0-9_-]{11}$');

  static bool isValid(String? raw) {
    final id = normalize(raw);
    return id != null;
  }

  static String? normalize(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (_idPattern.hasMatch(trimmed)) return trimmed;
    if (trimmed.contains('googlevideo.com') ||
        trimmed.contains('youtube.com/api/')) {
      return null;
    }
    final loose = ChatRoomDjState.videoIdFromLoose(trimmed);
    if (loose != null && _idPattern.hasMatch(loose)) return loose;
    return null;
  }

  static String? fromDj({
    String? currentVideoId,
    String? nowPlayingUrl,
  }) {
    return normalize(currentVideoId) ?? normalize(nowPlayingUrl);
  }
}
