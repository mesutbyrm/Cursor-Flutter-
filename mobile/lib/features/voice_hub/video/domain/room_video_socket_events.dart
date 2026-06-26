import '../../music/domain/entities/room_playback_sync.dart';
import 'youtube_video_id.dart';

/// WebSocket / SSE video müzik olayları — `dj`, `music`, `roomVideo`.
abstract final class RoomVideoSocketEvents {
  static const play = 'play';
  static const pause = 'pause';
  static const close = 'close';
  static const sync = 'sync';

  static const socketEventName = 'roomVideo';
  static const legacyDjEvent = 'dj';
  static const legacyMusicEvent = 'music';

  /// Sunucu yükünden video kontrol eylemini çıkarır.
  static String? actionFromPayload(Map<String, dynamic> map) {
    final explicit = map['action']?.toString().toLowerCase();
    if (explicit == play ||
        explicit == pause ||
        explicit == close ||
        explicit == sync) {
      return explicit;
    }
    final type = map['type']?.toString().toLowerCase();
    if (type == 'roomvideo') {
      return map['event']?.toString().toLowerCase() ?? sync;
    }
    if (map['playing'] == false && map['currentVideoId'] == null) {
      return close;
    }
    if (map['playing'] == false) return pause;
    if (map['playing'] == true) return play;
    return null;
  }

  static RoomPlaybackSync? syncFromPayload(Map<String, dynamic> map) {
    final videoId = YoutubeVideoId.normalize(map['currentVideoId']?.toString());
    if (videoId == null) {
      final np = map['nowPlaying'];
      if (np is Map) {
        final fromNp = YoutubeVideoId.normalize(
          np['videoId']?.toString() ?? np['youtubeUrl']?.toString(),
        );
        if (fromNp == null && map['playing'] != true) return null;
      } else if (map['playing'] != true) {
        return null;
      }
    }
    return RoomPlaybackSync.fromPayload(map);
  }

  static bool isVideoPayload(Map<String, dynamic> map) {
    if (map['type']?.toString().toLowerCase() == 'roomvideo') return true;
    if (map.containsKey('currentVideoId')) return true;
    if (map.containsKey('nowPlaying')) {
      final np = map['nowPlaying'];
      if (np is Map) {
        final withVideo = np['withVideo'] == true ||
            np['requestType']?.toString().toLowerCase() == 'video' ||
            np['videoMode']?.toString().toLowerCase() == 'video';
        if (!withVideo) return false;
        return np['videoId'] != null || np['youtubeUrl'] != null;
      }
    }
    return false;
  }
}
