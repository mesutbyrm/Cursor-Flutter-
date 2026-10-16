import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/auth_selectors.dart';
import '../../../feed/domain/entities/post_entity.dart';
import 'social_providers.dart';

/// GirLive Sosyal tam ekran akış — `feed`: `all` (Keşfet) | `following`
/// (Takip Ettiğin). Her sayfa bir paylaşım; sona yaklaşınca devamı yüklenir.
class SocialReelsNotifier
    extends FamilyAsyncNotifier<List<PostEntity>, String> {
  int _page = 1;
  bool _end = false;
  bool _loadingMore = false;

  bool get hasMore => !_end;

  Future<({List<PostEntity> posts, bool hasMore})> _fetch(
    int page, {
    bool force = false,
  }) {
    return ref.read(socialRemoteProvider).fetch(
          page: page,
          feed: arg,
          currentUserId: ref.read(currentUserIdProvider),
          forceRefresh: force,
        );
  }

  @override
  Future<List<PostEntity>> build(String feed) async {
    _page = 1;
    _end = false;
    final r = await _fetch(1);
    _end = !r.hasMore;
    return r.posts;
  }

  Future<void> refresh() async {
    final prev = state;
    state = const AsyncValue<List<PostEntity>>.loading().copyWithPrevious(prev);
    state = await AsyncValue.guard(() async {
      _page = 1;
      _end = false;
      final r = await _fetch(1, force: true);
      _end = !r.hasMore;
      return r.posts;
    });
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || _end || _loadingMore) return;
    _loadingMore = true;
    try {
      final r = await _fetch(_page + 1);
      if (r.posts.isEmpty) {
        _end = true;
        return;
      }
      _page++;
      _end = !r.hasMore;
      final ids = cur.map((p) => p.id).toSet();
      state = AsyncValue.data([
        ...cur,
        ...r.posts.where((p) => !ids.contains(p.id)),
      ]);
    } catch (_) {
      // Sessiz: bir sonraki kaydırmada yeniden denenir.
    } finally {
      _loadingMore = false;
    }
  }

  void updatePost(PostEntity post) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncValue.data([
      for (final p in cur) p.id == post.id ? post : p,
    ]);
  }

  void removePost(String postId) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    state = AsyncValue.data(cur.where((p) => p.id != postId).toList());
  }
}

final socialReelsProvider = AsyncNotifierProvider.family<SocialReelsNotifier,
    List<PostEntity>, String>(SocialReelsNotifier.new);
