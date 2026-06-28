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
    this.giftTo,
    this.note,
    this.uploader,
    this.duration,
    this.requestType,
    this.withVideo = false,
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
      thumbUrl: json['thumbUrl']?.toString() ??
          json['thumbnail']?.toString() ??
          json['image']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      requestedBy: user,
      giftTo: json['giftTo']?.toString(),
      note: json['note']?.toString(),
      uploader: json['uploader']?.toString() ??
          json['channelTitle']?.toString() ??
          json['channel']?.toString() ??
          json['artist']?.toString(),
      duration: json['duration']?.toString(),
      requestType: _parseRequestType(json),
      withVideo: _isVideoRequest(json),
    );
  }

  static String? _parseRequestType(Map<String, dynamic> json) {
    final raw = json['requestType']?.toString().toLowerCase().trim();
    if (raw == 'audio' || raw == 'video') return raw;
    return null;
  }

  static bool _isVideoRequest(Map<String, dynamic> json) {
    final type = _parseRequestType(json);
    if (type == 'video') return true;
    if (type == 'audio') return false;
    return json['withVideo'] == true ||
        json['playWithVideo'] == true ||
        json['isVideo'] == true ||
        json['videoMode']?.toString().toLowerCase() == 'video' ||
        json['mode']?.toString().toLowerCase() == 'video';
  }

  final String id;
  final String title;
  final String youtubeUrl;
  final String? thumbUrl;
  final DateTime createdAt;
  final ChatRoomUserRef? requestedBy;
  final String? giftTo;
  final String? note;
  final String? uploader;
  final String? duration;
  final String? requestType;
  final bool withVideo;

  bool get isVideoRequest => requestType == 'video' || withVideo;
  bool get isAudioRequest => requestType == 'audio' || !isVideoRequest;

  /// İstemci video isteği gönderdiğinde sunucu bayrağı eksikse tamamlar.
  MusicQueueItem asVideoRequest() {
    if (isVideoRequest) return this;
    return MusicQueueItem(
      id: id,
      title: title,
      youtubeUrl: youtubeUrl,
      createdAt: createdAt,
      thumbUrl: thumbUrl,
      requestedBy: requestedBy,
      giftTo: giftTo,
      note: note,
      uploader: uploader,
      duration: duration,
      requestType: 'video',
      withVideo: true,
    );
  }

  String get artistLine {
    final parts = <String>[];
    if (uploader != null && uploader!.isNotEmpty) parts.add(uploader!);
    if (duration != null && duration!.isNotEmpty) parts.add(duration!);
    return parts.join(' • ');
  }

  @override
  List<Object?> get props => [
        id,
        title,
        youtubeUrl,
        thumbUrl,
        createdAt,
        requestedBy,
        giftTo,
        note,
        uploader,
        duration,
        requestType,
        withVideo,
      ];
}

class YoutubeSearchHit extends Equatable {
  const YoutubeSearchHit({
    required this.videoId,
    required this.title,
    required this.url,
    this.thumbUrl,
    this.uploader,
    this.duration,
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
      thumbUrl: json['thumbUrl']?.toString() ??
          json['thumbnail']?.toString() ??
          json['image']?.toString(),
      uploader: json['uploader']?.toString() ??
          json['channelTitle']?.toString() ??
          json['channel']?.toString(),
      duration: json['duration']?.toString(),
    );
  }

  final String videoId;
  final String title;
  final String url;
  final String? thumbUrl;
  final String? uploader;
  final String? duration;

  String get subtitleLine {
    final parts = <String>[];
    if (uploader != null && uploader!.isNotEmpty) parts.add(uploader!);
    if (duration != null && duration!.isNotEmpty) parts.add(duration!);
    return parts.join(' • ');
  }

  @override
  List<Object?> get props => [videoId, title, url, thumbUrl, uploader, duration];
}
