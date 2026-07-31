import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../fortune/data/fortune_share_preferences.dart';
import '../../../fortune/presentation/providers/fortune_share_preferences_provider.dart';
import '../providers/social_providers.dart';

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
        PostEntity? match;
        for (final p in page.posts) {
          if (postIdHint != null &&
              postIdHint.isNotEmpty &&
              p.id == postIdHint) {
            match = p;
            break;
          }
        }
        if (match == null) {
          for (final p in page.posts) {
            if (authorId != null &&
                authorId.isNotEmpty &&
                p.author.id != authorId) {
              continue;
            }
            if (!p.isAutoShare && p.postType != 'fortune') continue;
            if (fortuneId != null &&
                fortuneId.isNotEmpty &&
                p.fortuneId != null &&
                p.fortuneId != fortuneId) {
              continue;
            }
            match = p;
            break;
          }
        }

        if (match != null) {
          _ref.read(socialNotifierProvider.notifier).prependPost(match);
          final aid = match.author.id;
          if (aid.isNotEmpty) {
            _ref.invalidate(userSocialPostsProvider(aid));
          }
          return;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('SocialFortuneFeedSync: $e');
      }
    }

    await _ref.read(socialNotifierProvider.notifier).refresh();
  }
}

final socialFortuneFeedSyncProvider = Provider<SocialFortuneFeedSync>((ref) {
  return SocialFortuneFeedSync(ref);
});
