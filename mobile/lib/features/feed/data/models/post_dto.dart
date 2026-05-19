import '../../../../core/util/json_util.dart';
import '../../../auth/data/models/user_dto.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/post_entity.dart';

class PostDto {
  PostDto({
    required this.id,
    required this.author,
    this.caption,
    this.mediaUrl,
    this.likesCount,
    this.commentsCount,
    this.createdAt,
    this.fortuneType,
    this.viewCount,
    this.isAutoShare,
    this.durationSeconds,
  });

  factory PostDto.fromJson(Map<String, dynamic> json) {
    final authorRaw = pick(json, ['author', 'user', 'creator']);
    Map<String, dynamic> authorMap =
        authorRaw is Map ? asJsonMap(authorRaw) : <String, dynamic>{};
    if (authorMap.isEmpty) {
      authorMap = {
        'id': pick(json, ['userId', 'authorId', 'uid'])?.toString() ?? '',
        'username': pick(json, ['username', 'handle'])?.toString() ?? 'user',
        'displayName': pick(json, ['displayName', 'authorName']) as String?,
        'avatarUrl': pick(json, ['avatarUrl', 'authorAvatar']) as String?,
      };
    }

    var likes = asInt(pick(json, ['likesCount', 'likes', 'likeCount']));
    var comments = asInt(pick(json, ['commentsCount', 'comments']));
    final countRaw = json['_count'];
    if (countRaw is Map) {
      final cm = Map<String, dynamic>.from(countRaw);
      if (cm.containsKey('likes')) likes = asInt(cm['likes']);
      if (cm.containsKey('comments')) comments = asInt(cm['comments']);
    }

    return PostDto(
      id: pick(json, ['id', '_id', 'postId', 'storyId', 'mediaId'])
              ?.toString() ??
          '',
      author: UserDto.fromJson(authorMap).toEntity(),
      caption: pick(json, ['caption', 'text', 'description', 'content'])
          as String?,
      mediaUrl: pick(json, [
            'mediaUrl',
            'media_url',
            'videoUrl',
            'thumbnailUrl',
            'imageUrl',
          ])
          as String?,
      likesCount: likes,
      commentsCount: comments,
      createdAt: _parseDate(pick(json, ['createdAt', 'created_at', 'timestamp'])),
      fortuneType: pick(json, ['fortuneType', 'fortune_type'])?.toString(),
      viewCount: asInt(pick(json, ['viewCount', 'views'])),
      isAutoShare: json['isAuto'] == true,
      durationSeconds: _pickDurationSeconds(json),
    );
  }

  static int? _pickDurationSeconds(Map<String, dynamic> json) {
    final v = pick(json, [
      'durationSeconds',
      'duration',
      'videoDuration',
      'lengthSeconds',
      'video_duration',
    ]);
    if (v == null) return null;
    if (v is num) return v.round().clamp(0, 86400).toInt();
    final s = v.toString();
    final parsed = int.tryParse(s);
    if (parsed != null) return parsed.clamp(0, 86400).toInt();
    if (s.contains(':')) {
      final parts = s.split(':').map((e) => int.tryParse(e.trim()) ?? 0).toList();
      if (parts.isEmpty) return null;
      if (parts.length == 2) return (parts[0] * 60 + parts[1]).clamp(0, 86400).toInt();
      if (parts.length >= 3) {
        return (parts[0] * 3600 + parts[1] * 60 + parts[2]).clamp(0, 86400).toInt();
      }
    }
    return null;
  }

  final String id;
  final UserEntity author;
  final String? caption;
  final String? mediaUrl;
  final int? likesCount;
  final int? commentsCount;
  final DateTime? createdAt;
  final String? fortuneType;
  final int? viewCount;
  final bool? isAutoShare;
  final int? durationSeconds;

  PostEntity toEntity() {
    return PostEntity(
      id: id,
      author: author,
      caption: caption,
      mediaUrl: mediaUrl,
      likesCount: likesCount ?? 0,
      commentsCount: commentsCount ?? 0,
      createdAt: createdAt,
      fortuneType: fortuneType,
      viewCount: viewCount ?? 0,
      isAutoShare: isAutoShare ?? false,
      durationSeconds: durationSeconds,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
