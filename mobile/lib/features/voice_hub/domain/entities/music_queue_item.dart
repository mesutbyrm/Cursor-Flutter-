import 'package:equatable/equatable.dart';

import 'chat_room_message.dart';

class MusicQueueItem extends Equatable {
  const MusicQueueItem({
    required this.id,
    required this.title,
    required this.youtubeUrl,
    required this.createdAt,
    this.thumbUrl,
    this.requestedBy,
  });

  factory MusicQueueItem.fromJson(Map<String, dynamic> json) {
    ChatRoomUserRef? user;
    final u = json['requestedBy'] ?? json['user'];
    if (u is Map) {
      user = ChatRoomUserRef.fromJson(Map<String, dynamic>.from(u));
    }
    final videoId = json['videoId']?.toString();
    final url = json['youtubeUrl']?.toString() ??
        json['url']?.toString() ??
        (videoId != null && videoId.isNotEmpty
            ? 'https://www.youtube.com/watch?v=$videoId'
            : '');
    return MusicQueueItem(
      id: json['id']?.toString() ?? videoId ?? '',
      title: json['title']?.toString() ?? 'Şarkı',
      youtubeUrl: url,
      thumbUrl: json['thumbUrl']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      requestedBy: user,
    );
  }

  final String id;
  final String title;
  final String youtubeUrl;
  final String? thumbUrl;
  final DateTime createdAt;
  final ChatRoomUserRef? requestedBy;

  @override
  List<Object?> get props => [id, title, youtubeUrl, thumbUrl, createdAt, requestedBy];
}

class YoutubeSearchHit extends Equatable {
  const YoutubeSearchHit({
    required this.videoId,
    required this.title,
    required this.url,
    this.thumbUrl,
    this.uploader,
  });

  factory YoutubeSearchHit.fromJson(Map<String, dynamic> json) {
    final vid = json['videoId']?.toString() ?? json['id']?.toString() ?? '';
    return YoutubeSearchHit(
      videoId: vid,
      title: json['title']?.toString() ?? 'Video',
      url: json['url']?.toString().isNotEmpty == true
          ? json['url']!.toString()
          : (vid.isNotEmpty
              ? 'https://www.youtube.com/watch?v=$vid'
              : ''),
      thumbUrl: json['thumbUrl']?.toString(),
      uploader: json['uploader']?.toString(),
    );
  }

  final String videoId;
  final String title;
  final String url;
  final String? thumbUrl;
  final String? uploader;

  @override
  List<Object?> get props => [videoId, title, url, thumbUrl, uploader];
}
