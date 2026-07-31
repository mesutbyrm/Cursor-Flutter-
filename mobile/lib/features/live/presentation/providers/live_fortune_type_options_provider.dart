import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live_psychics/presentation/widgets/psychic_fortune_types.dart';
import '../../../platform/data/models/fortune_request_type.dart';
import '../../../platform/presentation/providers/platform_content_providers.dart';
import 'live_fortune_request_provider.dart';

/// API kataloğu + yerel yedek — canlı fal formu tür listesi.
final liveFortuneTypeOptionsProvider =
    FutureProvider.autoDispose<List<PsychicFortuneType>>((ref) async {
  final remote = await ref.watch(fortuneRequestTypesProvider.future);
  if (remote.isEmpty) return psychicFortuneTypes;
  return remote
      .map(
        (FortuneRequestType t) =>
            PsychicFortuneType(key: t.key, label: t.label),
      )
      .toList();
});

/// İzleyicinin aktif fal isteği durumu.
final liveFortuneMyStatusProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, streamId) async {
  return ref
      .read(liveFortuneRequestDataSourceProvider)
      .fetchMyStatus(streamId);
});
