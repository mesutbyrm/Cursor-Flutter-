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
    this.viewsCount,
    this.isLiked,
    this.createdAt,
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
    return PostDto(
      id: pick(json, ['id', '_id', 'postId', 'storyId', 'mediaId'])
              ?.toString() ??
          '',
      author: UserDto.fromJson(authorMap).toEntity(),
      caption: pick(json, ['caption', 'text', 'description']) as String?,
      mediaUrl: pick(json, [
            'mediaUrl',
            'media_url',
            'videoUrl',
            'thumbnailUrl',
            'imageUrl',
          ])
          as String?,
      likesCount: asInt(pick(json, ['likesCount', 'likes', 'likeCount'])),
      commentsCount: asInt(pick(json, ['commentsCount', 'comments'])),
      viewsCount: asInt(pick(json, [
        'viewsCount',
        'views',
        'viewCount',
        'plays',
        'playCount',
      ])),
      isLiked: pick(json, ['isLiked', 'liked', 'hasLiked']) == true ||
          pick(json, ['isLiked', 'liked', 'hasLiked']) == 1,
      createdAt: _parseDate(pick(json, ['createdAt', 'created_at', 'timestamp'])),
    );
  }

  final String id;
  final UserEntity author;
  final String? caption;
  final String? mediaUrl;
  final int? likesCount;
  final int? commentsCount;
  final int? viewsCount;
  final bool? isLiked;
  final DateTime? createdAt;

  PostEntity toEntity() {
    return PostEntity(
      id: id,
      author: author,
      caption: caption,
      mediaUrl: mediaUrl,
      likesCount: likesCount ?? 0,
      commentsCount: commentsCount ?? 0,
      viewsCount: viewsCount ?? 0,
      isLiked: isLiked ?? false,
      createdAt: createdAt,
    );
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
