import '../../../../core/util/json_util.dart';

/// Odada çalınmış şarkı — `GET /api/music/history?roomId=&limit=`.
class RoomMusicHistoryEntry {
  const RoomMusicHistoryEntry({
    required this.id,
    required this.videoId,
    required this.title,
    this.duration = '',
    this.isVideo = false,
    this.isPaid = false,
    this.playedAt,
    this.requestedByName,
    this.requestedByImage,
  });

  final String id;
  final String videoId;
  final String title;
  final String duration;
  final bool isVideo;
  final bool isPaid;
  final DateTime? playedAt;
  final String? requestedByName;
  final String? requestedByImage;

  static List<RoomMusicHistoryEntry> listFromResponse(dynamic body) {
    final map = asJsonMap(body);
    final raw = asJsonList(map['history'] ?? map['data'] ?? body);
    return raw
        .map((e) => RoomMusicHistoryEntry.fromJson(asJsonMap(e)))
        .where((e) => e.title.isNotEmpty || e.videoId.isNotEmpty)
        .toList(growable: false);
  }

  factory RoomMusicHistoryEntry.fromJson(Map<String, dynamic> json) {
    final by = asJsonMap(json['requestedBy']);
    return RoomMusicHistoryEntry(
      id: json['id']?.toString() ?? '',
      videoId: json['videoId']?.toString().trim() ?? '',
      title: json['title']?.toString().trim() ?? '',
      duration: json['duration']?.toString().trim() ?? '',
      isVideo: json['requestType']?.toString() == 'video',
      isPaid: json['isPaid'] == true,
      playedAt: DateTime.tryParse(json['playedAt']?.toString() ?? ''),
      requestedByName: by['name']?.toString(),
      requestedByImage: by['image']?.toString(),
    );
  }
}
