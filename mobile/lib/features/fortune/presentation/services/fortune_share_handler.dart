import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/fortune_share_preferences.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../providers/fortune_share_preferences_provider.dart';
import '../../../social/domain/entities/share_fortune_input.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../../social/presentation/services/social_fortune_feed_sync.dart';

/// Fal paylaşımı — backend `POST /api/social/posts/auto-fortune` (web ile aynı).
class FortuneShareHandler {
  FortuneShareHandler(this._ref);

  final Ref _ref;

  /// Kullanıcı tercihi açıksa backend'e paylaşım oluştur; akışa anında ekle.
  Future<bool> autoShareIfEnabled(FortuneReadingResult result) async {
    final mode = await _ref.read(fortuneAutoShareModeProvider.future);
    if (mode == FortuneAutoShareMode.off ||
        mode == FortuneAutoShareMode.profileOnly) {
      return false;
    }
    return _shareViaBackend(result, mode: mode);
  }

  Future<void> shareToSocialFeed(FortuneReadingResult result) =>
      _shareViaBackend(result, mode: FortuneAutoShareMode.public);

  Future<void> shareToProfile(FortuneReadingResult result) =>
      _shareViaBackend(result, mode: FortuneAutoShareMode.profileOnly);

  Future<void> sharePublic(FortuneReadingResult result) =>
      _shareViaBackend(result, mode: FortuneAutoShareMode.public);

  Future<bool> _shareViaBackend(
    FortuneReadingResult result, {
    required FortuneAutoShareMode mode,
  }) async {
    if (mode == FortuneAutoShareMode.off) return false;
    final me = _ref.read(authControllerProvider).valueOrNull;
    if (me == null) return false;

    final summary = result.summary.trim();
    if (summary.isEmpty) return false;

    try {
      final rawPost = await _ref.read(socialRepositoryProvider).shareFortuneAuto(
            ShareFortuneInput(
              fortuneSlug: result.type.slug,
              fortuneType: result.type.title,
              summary: summary,
              detail: result.detail.trim().isNotEmpty ? result.detail : null,
              imageUrl: result.imageUrl,
              fortuneId: result.recordId,
              visualAnalysis: result.visualAnalysis,
              visibility: mode.apiVisibility,
            ),
          );
      final detail = result.detail.trim();
      final post = rawPost.fortuneDetail?.trim().isNotEmpty == true
          ? rawPost
          : rawPost.copyWith(
              fortuneDetail: detail.isNotEmpty ? detail : rawPost.fortuneDetail,
            );
      _ref.read(socialNotifierProvider.notifier).prependPost(post);
      final aid = post.author.id;
      if (aid.isNotEmpty) {
        _ref.invalidate(userSocialPostsProvider(aid));
      }
      return true;
    } catch (_) {
      // Sunucu gecikmesi — poll ile yedek senkron.
      await _ref.read(socialFortuneFeedSyncProvider).afterFortuneCompleted(
            fortuneId: result.recordId,
          );
      return false;
    }
  }
}

final fortuneShareHandlerProvider = Provider<FortuneShareHandler>((ref) {
  return FortuneShareHandler(ref);
});
