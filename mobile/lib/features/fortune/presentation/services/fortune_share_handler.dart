import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../social/domain/entities/share_fortune_input.dart';
import '../../../social/presentation/providers/social_providers.dart';
import '../../data/fortune_share_preferences.dart';
import '../../domain/entities/fortune_type_entity.dart';
import '../providers/fortune_share_preferences_provider.dart';

/// Fal paylaşımı — otomatik mod + manuel hedefler.
class FortuneShareHandler {
  FortuneShareHandler(this._ref);

  final Ref _ref;

  Future<void> autoShareIfEnabled(FortuneReadingResult result) async {
    final mode = await _ref.read(fortuneAutoShareModeProvider.future);
    if (mode == FortuneAutoShareMode.off) return;
    await _share(result, mode);
  }

  Future<void> shareToSocialFeed(FortuneReadingResult result) =>
      _share(result, FortuneAutoShareMode.public);

  Future<void> shareToProfile(FortuneReadingResult result) =>
      _share(result, FortuneAutoShareMode.profileOnly);

  Future<void> sharePublic(FortuneReadingResult result) =>
      _share(result, FortuneAutoShareMode.public);

  Future<void> _share(
    FortuneReadingResult result,
    FortuneAutoShareMode mode,
  ) async {
    final me = _ref.read(authControllerProvider).valueOrNull;
    if (me == null) return;

    await _ref.read(socialRepositoryProvider).shareFortuneAuto(
          ShareFortuneInput(
            fortuneSlug: result.type.slug,
            fortuneType: result.type.title,
            summary: result.summary,
            detail: result.fullText,
            imageUrl: result.imageUrl,
            fortuneId: result.recordId,
            visualAnalysis: result.visualAnalysis,
            visibility: mode.apiVisibility,
          ),
        );
    _ref.invalidate(socialNotifierProvider);
  }
}

final fortuneShareHandlerProvider = Provider<FortuneShareHandler>((ref) {
  return FortuneShareHandler(ref);
});
