import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/datasources/search_remote_datasource.dart';
import '../../data/repositories/search_repository_impl.dart';
import '../../domain/entities/search_user_entity.dart';
import '../../domain/repositories/search_repository.dart';

final searchRemoteProvider = Provider<SearchRemoteDataSource>((ref) {
  return SearchRemoteDataSource(ref.watch(dioProvider));
});

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepositoryImpl(ref.watch(searchRemoteProvider));
});

/// Debounced kullanıcı araması — `GET /api/users/search`.
final userSearchProvider =
    AsyncNotifierProvider<UserSearchNotifier, List<SearchUserEntity>>(
  UserSearchNotifier.new,
);

class UserSearchNotifier extends AsyncNotifier<List<SearchUserEntity>> {
  Timer? _debounce;
  String _lastQuery = '';

  @override
  Future<List<SearchUserEntity>> build() async => const [];

  void setQuery(String query) {
    _debounce?.cancel();
    final q = query.trim();
    _lastQuery = q;

    if (q.length < 2) {
      state = const AsyncData([]);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _runSearch(q);
    });
  }

  Future<void> _runSearch(String q) async {
    if (q != _lastQuery) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return ref.read(searchRepositoryProvider).searchUsers(q);
    });
  }

  Future<void> refresh() async {
    if (_lastQuery.length < 2) return;
    await _runSearch(_lastQuery);
  }
}
