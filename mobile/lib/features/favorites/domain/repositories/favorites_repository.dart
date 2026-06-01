import '../entities/user_favorite_entity.dart';

class AddFavoriteInput {
  const AddFavoriteInput({
    required this.targetType,
    required this.targetId,
    this.title,
    this.url,
    this.imageUrl,
  });

  final String targetType;
  final String targetId;
  final String? title;
  final String? url;
  final String? imageUrl;
}

abstract class FavoritesRepository {
  Future<List<UserFavoriteEntity>> list();

  Future<UserFavoriteEntity> add(AddFavoriteInput input);

  Future<void> remove(String id);
}
