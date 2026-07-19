import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../feed/presentation/widgets/discover_premium_2026/discover_premium_sections.dart';
import '../../../../live/domain/entities/voice_room_sort.dart';
import '../../../../live/presentation/providers/live_providers.dart';
import '../../../../vip_gold/presentation/utils/open_voice_room_vip.dart';

/// Ana sayfa — premium sesli oda yatay şeridi (DiscoverPremiumRoomCard).
class DiscoverPremiumHomeSection extends ConsumerWidget {
  const DiscoverPremiumHomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(voiceRoomsProvider);

    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (rooms) {
        final top = sortVoiceRoomsByPopularity(rooms).take(10).toList();
        if (top.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            DiscoverPremiumRoomRow(
              title: 'Premium Sesli Odalar',
              rooms: top,
              actionLabel: 'Tümü',
              onAction: () => context.push('/voice-rooms'),
              onRoomTap: (room) => openVoiceRoomWithVipGate(context, ref, room),
            ),
          ],
        );
      },
    );
  }
}
