import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../vip_gold/presentation/widgets/gold_team_top_entrance_banner.dart';
import '../../providers/voice_room_gold_entrance_provider.dart';

/// Sesli oda — Gold+ kullanıcı girişi (takım amblemi, üstten).
class VoiceRoomGoldEntranceHost extends ConsumerWidget {
  const VoiceRoomGoldEntranceHost({
    super.key,
    required this.roomKey,
    this.topInset = 56,
  });

  final String roomKey;
  final double topInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(voiceRoomGoldEntranceProvider(roomKey));
    if (event == null) return const SizedBox.shrink();

    return GoldTeamTopEntranceBanner(
      key: ValueKey('gold_entrance_${event.userName}_${event.tier.name}'),
      userName: event.userName,
      tier: event.tier,
      theme: event.theme,
      profileImageUrl: event.avatarUrl,
      topInset: topInset,
      onFinished: () =>
          ref.read(voiceRoomGoldEntranceProvider(roomKey).notifier).clear(),
    );
  }
}
