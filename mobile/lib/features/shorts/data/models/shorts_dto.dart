import '../../domain/entities/shorts_entity.dart';

class ShortVideoDTO {
  final String id, userId, username, title, description, videoUrl;
  final String? thumbnailUrl;
  final DateTime createdAt;
  final int likes, comments, shares, views;
  final bool isLiked;

  ShortVideoDTO({required this.id, required this.userId, required this.username, required this.title, required this.description, required this.videoUrl, this.thumbnailUrl, required this.createdAt, required this.likes, required this.comments, required this.shares, required this.views, required this.isLiked});

  factory ShortVideoDTO.fromJson(Map<String,dynamic> json) => ShortVideoDTO(id: json['_id']?.toString() ?? '', userId: json['userId']?.toString() ?? '', username: json['username']?.toString() ?? '', title: json['title']?.toString() ?? '', description: json['description']?.toString() ?? '', videoUrl: json['videoUrl']?.toString() ?? '', thumbnailUrl: json['thumbnailUrl']?.toString(), createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(), likes: (json['likes'] as num?)?.toInt() ?? 0, comments: (json['comments'] as num?)?.toInt() ?? 0, shares: (json['shares'] as num?)?.toInt() ?? 0, views: (json['views'] as num?)?.toInt() ?? 0, isLiked: json['isLiked'] == true);

  ShortVideo toDomain() => ShortVideo(id: id, userId: userId, username: username, title: title, description: description, videoUrl: videoUrl, thumbnailUrl: thumbnailUrl, createdAt: createdAt, likes: likes, comments: comments, shares: shares, views: views, isLiked: isLiked);
}

class ShortVideoRemixDTO {
  final String id, originalVideoId, remixUserId, title, remixType;
  final int duets;
  final DateTime createdAt;
  final bool trending;

  ShortVideoRemixDTO({required this.id, required this.originalVideoId, required this.remixUserId, required this.title, required this.remixType, required this.duets, required this.createdAt, required this.trending});

  factory ShortVideoRemixDTO.fromJson(Map<String,dynamic> json) => ShortVideoRemixDTO(id: json['_id']?.toString() ?? '', originalVideoId: json['originalVideoId']?.toString() ?? '', remixUserId: json['remixUserId']?.toString() ?? '', title: json['title']?.toString() ?? '', remixType: json['remixType']?.toString() ?? '', duets: (json['duets'] as num?)?.toInt() ?? 0, createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(), trending: json['trending'] == true);

  ShortVideoRemix toDomain() => ShortVideoRemix(id: id, originalVideoId: originalVideoId, remixUserId: remixUserId, title: title, remixType: remixType, duets: duets, createdAt: createdAt, trending: trending);
}
