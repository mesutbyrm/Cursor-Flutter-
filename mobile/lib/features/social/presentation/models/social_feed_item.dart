import '../../../feed/domain/entities/post_entity.dart';
import '../../../live/domain/entities/live_stream_entity.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../shorts/domain/entities/short_video_entity.dart';

/// GirLive Sosyal akış öğesi: paylaşım (yazı/görsel/fal), video, canlı yayın,
/// sesli oda veya reklam sayfası.
sealed class SocialFeedItem {
  const SocialFeedItem();
  String get key;
}

class PostFeedItem extends SocialFeedItem {
  const PostFeedItem(this.post);
  final PostEntity post;
  @override
  String get key => 'post-${post.id}';
}

class ShortFeedItem extends SocialFeedItem {
  const ShortFeedItem(this.video);
  final ShortVideoEntity video;
  @override
  String get key => 'short-${video.id}';
}

class LiveFeedItem extends SocialFeedItem {
  const LiveFeedItem(this.stream);
  final LiveStreamEntity stream;
  @override
  String get key => 'live-${stream.id}';
}

class RoomFeedItem extends SocialFeedItem {
  const RoomFeedItem(this.room);
  final VoiceRoomEntity room;
  @override
  String get key => 'room-${room.id}';
}

/// Her 5 öğeden sonra: AdMob geçiş reklamı; yoksa site reklamı (tanıtım).
class AdFeedItem extends SocialFeedItem {
  const AdFeedItem(this.slot);
  final int slot;
  @override
  String get key => 'ad-$slot';
}

/// Her [every] içerikten sonra bir reklam sayfası ekler.
List<SocialFeedItem> withAdSlots(List<SocialFeedItem> items, {int every = 5}) {
  final out = <SocialFeedItem>[];
  var count = 0;
  var slot = 0;
  for (final it in items) {
    out.add(it);
    count++;
    if (count % every == 0) out.add(AdFeedItem(slot++));
  }
  return out;
}

/// Ana akış: paylaşımlar arasına trend videolar ve açık canlı yayınlar serpiştirilir
/// (yaklaşık 3 paylaşım → 1 video, 6 öğede bir canlı yayın).
List<SocialFeedItem> interleaveFeed({
  required List<PostEntity> posts,
  required List<ShortVideoEntity> videos,
  required List<LiveStreamEntity> lives,
}) {
  final out = <SocialFeedItem>[];
  var p = 0, v = 0, l = 0;
  while (p < posts.length || v < videos.length || l < lives.length) {
    for (var i = 0; i < 3 && p < posts.length; i++) {
      out.add(PostFeedItem(posts[p++]));
    }
    if (v < videos.length) out.add(ShortFeedItem(videos[v++]));
    if (l < lives.length && out.length >= 3 * (l + 1)) {
      out.add(LiveFeedItem(lives[l++]));
    }
    if (p >= posts.length && v >= videos.length) {
      while (l < lives.length) {
        out.add(LiveFeedItem(lives[l++]));
      }
    }
  }
  return out;
}


/// Video + paylaşım akışı: yüklenme saatine göre en yeni önce. Saati
/// bilinmeyenler sona, kendi aralarında gelen sırayla kalır.
List<SocialFeedItem> sortFeedByNewest(List<SocialFeedItem> items) {
  DateTime? at(SocialFeedItem i) => switch (i) {
        PostFeedItem(:final post) => post.createdAt,
        ShortFeedItem(:final video) => video.createdAt,
        _ => null,
      };
  final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
  indexed.sort((a, b) {
    final ta = at(a.$2);
    final tb = at(b.$2);
    if (ta != null && tb != null) {
      final c = tb.compareTo(ta);
      if (c != 0) return c;
    } else if (ta != null) {
      return -1;
    } else if (tb != null) {
      return 1;
    }
    return a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}
