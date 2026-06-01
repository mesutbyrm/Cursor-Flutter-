import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/favorites_remote_datasource.dart';
import '../../data/repositories/favorites_repository_impl.dart';
import '../../domain/entities/user_favorite_entity.dart';
import '../../domain/repositories/favorites_repository.dart';

final favoritesRemoteProvider = Provider<FavoritesRemoteDataSource>((ref) {
  return FavoritesRemoteDataSource(ref.watch(dioProvider));
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepositoryImpl(ref.watch(favoritesRemoteProvider));
});

final userFavoritesProvider =
    FutureProvider<List<UserFavoriteEntity>>((ref) async {
  return ref.watch(favoritesRepositoryProvider).list();
});
