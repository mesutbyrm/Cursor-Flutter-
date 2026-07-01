import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/short_explore_location_store.dart';
import '../../domain/entities/short_explore_entity.dart';
import 'shorts_providers.dart';

final shortExploreLocationProvider =
    AsyncNotifierProvider<ShortExploreLocationNotifier, ShortExploreLocation?>(
  ShortExploreLocationNotifier.new,
);

class ShortExploreLocation {
  const ShortExploreLocation({required this.label, this.lat, this.lng});

  final String label;
  final double? lat;
  final double? lng;
}

class ShortExploreLocationNotifier extends AsyncNotifier<ShortExploreLocation?> {
  @override
  Future<ShortExploreLocation?> build() async {
    final saved = await ShortExploreLocationStore.instance.read();
    if (saved.label == null || saved.label!.isEmpty) return null;
    return ShortExploreLocation(
      label: saved.label!,
      lat: saved.lat,
      lng: saved.lng,
    );
  }

  Future<void> setLocation(String label, {double? lat, double? lng}) async {
    await ShortExploreLocationStore.instance.save(
      label: label,
      lat: lat,
      lng: lng,
    );
    state = AsyncValue.data(
      ShortExploreLocation(label: label, lat: lat, lng: lng),
    );
    ref.invalidate(shortsExploreProvider);
  }

  Future<void> clear() async {
    await ShortExploreLocationStore.instance.clear();
    state = const AsyncValue.data(null);
    ref.invalidate(shortsExploreProvider);
  }
}

class ShortsExploreNotifier extends AsyncNotifier<ShortExplorePage> {
  String? _cursor;
  bool _hasMore = true;
  bool _loadingMore = false;
  String? _query;

  @override
  Future<ShortExplorePage> build() async {
    _cursor = null;
    _hasMore = true;
    _query = null;
    return _loadHub();
  }

  Future<ShortExplorePage> _loadHub() async {
    final loc = ref.read(shortExploreLocationProvider).valueOrNull;
    if (_query != null && _query!.isNotEmpty) {
      return ref.read(shortsRepositoryProvider).fetchExplore(query: _query);
    }
    return ref.read(shortsRepositoryProvider).fetchExploreHub(
          locationLabel: loc?.label,
          lat: loc?.lat,
          lng: loc?.lng,
        );
  }

  Future<void> search(String query) async {
    _query = query.trim().isEmpty ? null : query.trim();
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _cursor = null;
      _hasMore = true;
      if (_query != null) {
        return ref.read(shortsRepositoryProvider).fetchExplore(query: _query);
      }
      return _loadHub();
    });
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _cursor = null;
      _hasMore = true;
      if (_query != null) {
        return ref.read(shortsRepositoryProvider).fetchExplore(query: _query);
      }
      return _loadHub();
    });
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || !_hasMore || _loadingMore) return;
    _loadingMore = true;
    try {
      final page = await ref.read(shortsRepositoryProvider).fetchExplore(
            query: _query,
            cursor: _cursor,
          );
      if (page.videos.isEmpty) {
        _hasMore = false;
        return;
      }
      _cursor = page.nextCursor;
      _hasMore = page.hasMore;
      state = AsyncValue.data(
        cur.copyWith(
          videos: [...cur.videos, ...page.videos],
          trendingHashtags: page.trendingHashtags.isNotEmpty
              ? page.trendingHashtags
              : cur.trendingHashtags,
          popularMusic: page.popularMusic.isNotEmpty
              ? page.popularMusic
              : cur.popularMusic,
          nextCursor: page.nextCursor,
          hasMore: page.hasMore,
        ),
      );
    } finally {
      _loadingMore = false;
    }
  }
}

final shortsExploreProvider =
    AsyncNotifierProvider<ShortsExploreNotifier, ShortExplorePage>(
  ShortsExploreNotifier.new,
);
