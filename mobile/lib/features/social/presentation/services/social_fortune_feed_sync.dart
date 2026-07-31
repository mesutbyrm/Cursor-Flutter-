import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../fortune/presentation/providers/fortune_share_preferences_provider.dart';
import '../providers/social_providers.dart';
import 'social_fortune_post_match.dart';

/// Backend'in oluşturduğu fal paylaşımlarını sosyal akışa senkronize eder.
///
/// Flutter paylaşım oluşturmaz; yalnızca `GET /api/social/posts` ve bildirim
/// SSE (`fortune_share`) ile günceller.
class SocialFortuneFeedSync {
  SocialFortuneFeedSync(this._ref);

  final Ref _ref;
  final _seenPostIds = <String>{};

  /// Fal tamamlandıktan sonra backend paylaşımını bekle ve akışa al.
  Future<void> afterFortuneCompleted({
    String? fortuneId,
    String? postIdHint,
  }) async {
    final mode = await _ref.read(fortuneAutoShareModeProvider.future);
    if (mode == FortuneAutoShareMode.off) return;

    final me = _ref.read(authControllerProvider).valueOrNull;
    if (me == null) return;

    await _pullLatestFortunePost(
      authorId: me.id,
      fortuneId: fortuneId,
      postIdHint: postIdHint,
    );
  }

  /// Bildirim SSE — `type: fortune_share` (takip edilen kullanıcı).
  Future<void> onFortuneShareNotification({
    required String? postId,
    String? authorId,
  }) async {
    final id = postId?.trim();
    if (id != null && id.isNotEmpty) {
      if (!_seenPostIds.add(id)) return;
      final existing = _ref.read(socialNotifierProvider).valueOrNull;
      if (existing?.any((p) => p.id == id) == true) return;
    }

    await _pullLatestFortunePost(
      authorId: authorId,
      postIdHint: id,
    );
  }

  Future<void> _pullLatestFortunePost({
    String? authorId,
    String? fortuneId,
    String? postIdHint,
  }) async {
    final repo = _ref.read(socialRepositoryProvider);
    const delays = [
      Duration(milliseconds: 400),
      Duration(milliseconds: 900),
      Duration(milliseconds: 1800),
    ];

    for (final delay in delays) {
      await Future<void>.delayed(delay);
      try {
        final page = await repo.fetchPage(page: 1, forceRefresh: true);
        final match = findMatchingFortunePost(
          posts: page.posts,
          postIdHint: postIdHint,
          authorId: authorId,
          fortuneId: fortuneId,
        );

        if (match != null) {
          _prependToFeeds(match);
          return;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('SocialFortuneFeedSync: $e');
      }
    }

    await _ref.read(socialNotifierProvider.notifier).refresh();
  }

  void _prependToFeeds(PostEntity post) {
    _ref.read(socialNotifierProvider.notifier).prependPost(post);
    final aid = post.author.id;
    if (aid.isNotEmpty) {
      _ref.invalidate(userSocialPostsProvider(aid));
    }
  }
}

final socialFortuneFeedSyncProvider = Provider<SocialFortuneFeedSync>((ref) {
  return SocialFortuneFeedSync(ref);
});
