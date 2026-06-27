import 'music_queue_item.dart';

class PopularMusicSuggestion {
  const PopularMusicSuggestion({
    required this.title,
    required this.artist,
    required this.query,
    this.videoId,
  });

  factory PopularMusicSuggestion.fromJson(Map<String, dynamic> json) {
    return PopularMusicSuggestion(
      title: json['title']?.toString() ?? '',
      artist: json['artist']?.toString() ?? '',
      query: json['query']?.toString() ?? json['title']?.toString() ?? '',
      videoId: json['videoId']?.toString(),
    );
  }

  final String title;
  final String artist;
  final String query;
  final String? videoId;

  YoutubeSearchHit? toSearchHit() {
    final id = videoId?.trim() ?? '';
    if (id.length < 6) return null;
    return YoutubeSearchHit(
      videoId: id,
      title: title.isNotEmpty ? title : query,
      url: 'https://www.youtube.com/watch?v=$id',
      thumbUrl: 'https://i.ytimg.com/vi/$id/hqdefault.jpg',
      uploader: artist.isNotEmpty ? artist : null,
    );
  }
}
