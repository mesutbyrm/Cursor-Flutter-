import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/fortune_share_preferences.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../providers/fortune_share_preferences_provider.dart';
import '../../../social/presentation/services/social_fortune_feed_sync.dart';

/// Fal paylaşımı — backend tek kaynak; Flutter yalnızca senkronize eder.
class FortuneShareHandler {
  FortuneShareHandler(this._ref);

  final Ref _ref;

  /// Backend otomatik paylaşımı oluşturduktan sonra akışı güncelle.
  Future<bool> autoShareIfEnabled(FortuneReadingResult result) async {
    final mode = await _ref.read(fortuneAutoShareModeProvider.future);
    if (mode == FortuneAutoShareMode.off) return false;
    final me = _ref.read(authControllerProvider).valueOrNull;
    if (me == null) return false;

    await _ref.read(socialFortuneFeedSyncProvider).afterFortuneCompleted(
          fortuneId: result.recordId,
        );
    return true;
  }

  Future<void> shareToSocialFeed(FortuneReadingResult result) =>
      _syncBackendShare(result);

  Future<void> shareToProfile(FortuneReadingResult result) =>
      _syncBackendShare(result);

  Future<void> sharePublic(FortuneReadingResult result) =>
      _syncBackendShare(result);

  Future<void> _syncBackendShare(FortuneReadingResult result) async {
    final me = _ref.read(authControllerProvider).valueOrNull;
    if (me == null) return;

    await _ref.read(socialFortuneFeedSyncProvider).afterFortuneCompleted(
          fortuneId: result.recordId,
        );
  }
}

final fortuneShareHandlerProvider = Provider<FortuneShareHandler>((ref) {
  return FortuneShareHandler(ref);
});
