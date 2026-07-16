import '../../core/util/json_util.dart';

/// `GET /api/music/search` sonucu.
class ChatMusicHit {
  const ChatMusicHit({
    required this.videoId,
    required this.title,
    this.artist,
    this.thumbnail,
    this.duration,
  });

  final String videoId;
  final String title;
  final String? artist;
  final String? thumbnail;
  final String? duration;

  factory ChatMusicHit.fromJson(Map<String, dynamic> json) {
    return ChatMusicHit(
      videoId: pick(json, ['videoId', 'id', 'songId'])?.toString() ?? '',
      title: pick(json, ['title', 'name'])?.toString() ?? '',
      artist: pick(json, ['artist', 'channel', 'author'])?.toString(),
      thumbnail: pick(json, ['thumbnail', 'thumbUrl', 'image'])?.toString(),
      duration: pick(json, ['duration', 'durationLabel'])?.toString(),
    );
  }
}
