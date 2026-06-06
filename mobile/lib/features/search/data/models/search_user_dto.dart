import '../../../../core/util/json_util.dart';
import '../../domain/entities/search_user_entity.dart';

class SearchUserDto {
  SearchUserDto({
    required this.id,
    required this.name,
    required this.username,
    this.image,
    this.bio,
  });

  final String id;
  final String name;
  final String username;
  final String? image;
  final String? bio;

  factory SearchUserDto.fromJson(Map<String, dynamic> json) {
    return SearchUserDto(
      id: pick(json, ['id', '_id', 'userId'])?.toString() ?? '',
      name: pick(json, ['name', 'displayName', 'fullName'])?.toString() ?? '',
      username:
          pick(json, ['username', 'userName', 'handle'])?.toString() ?? '',
      image: pick(json, ['image', 'avatar', 'avatarUrl', 'photo'])?.toString(),
      bio: pick(json, ['bio', 'about'])?.toString(),
    );
  }

  SearchUserEntity toEntity() => SearchUserEntity(
        id: id,
        name: name,
        username: username,
        image: image,
        bio: bio,
      );
}
