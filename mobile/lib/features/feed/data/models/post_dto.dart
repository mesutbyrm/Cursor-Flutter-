import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/util/json_util.dart';
import '../../../auth/data/models/user_dto.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/post_entity.dart';

part 'post_dto.freezed.dart';

/// API satırı — esnek alan adları `fromApiMap` ile çözülür.
@freezed
abstract class PostDto with _$PostDto {
  const factory PostDto({
    required String id,
    required UserEntity author,
    String? caption,
    String? mediaUrl,
    @Default(0) int likesCount,
    @Default(0) int commentsCount,
    DateTime? createdAt,
    String? fortuneType,
    @Default(0) int viewCount,
    @Default(false) bool isAutoShare,
    @Default(0) int fortuneCount,
    String? postType,
    @Default(false) bool likedByMe,
  }) = _PostDto;

  const PostDto._();

  factory PostDto.fromApiMap(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
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

    var likes = asInt(pick(json, ['likesCount', 'likeCount']));
    var comments = asInt(pick(json, ['commentsCount']));
    final likesRaw = json['likes'];
    if (likesRaw is List) {
      likes = likesRaw.length;
    } else if (likes == 0) {
      likes = asInt(pick(json, ['likes']));
    }
    final commentsRaw = json['comments'];
    if (commentsRaw is List) {
      comments = commentsRaw.length;
    } else if (comments == 0) {
      comments = asInt(pick(json, ['comments']));
    }
    final countRaw = json['_count'];
    if (countRaw is Map) {
      final cm = Map<String, dynamic>.from(countRaw);
      if (cm.containsKey('likes')) likes = asInt(cm['likes']);
      if (cm.containsKey('comments')) comments = asInt(cm['comments']);
    }

    var likedByMe = json['likedByMe'] == true ||
        json['isLiked'] == true ||
        json['liked'] == true;
    if (!likedByMe &&
        currentUserId != null &&
        currentUserId.isNotEmpty &&
        likesRaw is List) {
      for (final l in likesRaw) {
        if (l is! Map) continue;
        final lm = asJsonMap(l);
        final uid = pick(lm, ['userId', 'id'])?.toString();
        if (uid == currentUserId) {
          likedByMe = true;
          break;
        }
      }
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
        'image_url',
      ]) as String?,
      likesCount: likes,
      commentsCount: comments,
      createdAt: _parseDate(pick(json, ['createdAt', 'created_at', 'timestamp'])),
      fortuneType: pick(json, ['fortuneType', 'fortune_type'])?.toString(),
      viewCount: asInt(pick(json, ['viewCount', 'views'])),
      isAutoShare: json['isAutoShare'] == true ||
          json['isAuto'] == true ||
          json['is_auto_share'] == true ||
          json['autoShared'] == true,
      fortuneCount: asInt(pick(json, ['fortuneCount', 'fortune_count'])),
      postType: pick(json, ['postType', 'post_type', 'type'])?.toString(),
      likedByMe: likedByMe,
    );
  }

  PostEntity toEntity() => PostEntity(
        id: id,
        author: author,
        caption: caption,
        mediaUrl: mediaUrl,
        likesCount: likesCount,
        commentsCount: commentsCount,
        createdAt: createdAt,
        fortuneType: fortuneType,
        viewCount: viewCount,
        isAutoShare: isAutoShare,
        fortuneCount: fortuneCount,
        postType: postType,
        likedByMe: likedByMe,
      );

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }
}
