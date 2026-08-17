import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/presentation/providers/live_providers.dart';
import '../providers/social_providers.dart';

/// Sosyal sekme pull-to-refresh — akış, hikâyeler ve aktif odalar.
Future<void> refreshSocialFeedSection(WidgetRef ref) async {
  ref.invalidate(socialStoryRingsProvider);
  ref.invalidate(liveStreamsProvider);
  ref.invalidate(voiceRoomsProvider);
  await ref.read(socialNotifierProvider.notifier).refresh();
}

/// Tek gönderi detayı pull-to-refresh.
Future<void> refreshSocialPostDetail(WidgetRef ref, String postId) async {
  final id = postId.trim();
  if (id.isEmpty) return;
  ref.invalidate(postDetailProvider(id));
  await ref.read(postDetailProvider(id).future);
}

/// Akışta gömülü aktif oda şeridi başlığı.
String buildSocialActiveRoomsEmbeddedTitle({
  required bool hasLive,
  required bool hasVoice,
}) {
  if (hasLive && hasVoice) return 'Canlı yayın ve sesli odalar';
  if (hasLive) return 'Canlı yayınlar';
  return 'Sesli sohbet odaları';
}
