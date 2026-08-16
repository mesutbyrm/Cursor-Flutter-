import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';

/// Canlı yayın veya sesli oda varsa sosyal akışta oda şeridi gösterilir.
bool socialActiveRoomsAvailable({
  List<LiveStreamEntity>? streams,
  List<VoiceRoomEntity>? rooms,
}) {
  if (streams != null && streams.any((x) => x.isLive)) return true;
  if (rooms != null && rooms.isNotEmpty) return true;
  return false;
}

abstract final class SocialFeedLayout {
  SocialFeedLayout._();

  static int itemCount(int postCount, {bool includeRoomStrips = true}) {
    if (postCount <= 0) return 0;
    if (!includeRoomStrips) return postCount;
    return postCount + postCount ~/ 2;
  }

  static bool isRoomsStrip(
    int feedIndex,
    int postCount, {
    bool includeRoomStrips = true,
  }) =>
      includeRoomStrips &&
      postIndexAt(feedIndex, postCount, includeRoomStrips: includeRoomStrips) ==
          null;

  /// Gönderi dizinindeki karşılık; oda şeridi için `null`.
  static int? postIndexAt(
    int feedIndex,
    int postCount, {
    bool includeRoomStrips = true,
  }) {
    if (!includeRoomStrips) {
      if (feedIndex < 0 || feedIndex >= postCount) return null;
      return feedIndex;
    }
    if (feedIndex < 0 || feedIndex >= itemCount(postCount)) return null;

    var fi = 0;
    var pi = 0;
    while (pi < postCount) {
      if (fi == feedIndex) return pi;
      fi++;
      pi++;
      if (pi >= postCount) break;

      if (fi == feedIndex) return pi;
      fi++;
      pi++;
      if (pi >= postCount) break;

      if (fi == feedIndex) return null;
      fi++;
    }
    return null;
  }
}
