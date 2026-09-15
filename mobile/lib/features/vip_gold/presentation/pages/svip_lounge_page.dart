import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/membership/membership_capability_gate.dart';
import '../../../../core/membership/membership_capability_keys.dart';
import '../../../../core/membership/membership_capability_providers.dart';
import '../../../../core/widgets/discover_tab_layout.dart';
import '../../../feed/presentation/widgets/discover/discover_background.dart';
import '../../../live/presentation/providers/voice_rooms_list_notifier.dart';
import '../../domain/voice_room_access.dart';
import '../utils/open_voice_room_vip.dart';

/// SVIP lounge — yalnızca `vip.svip_lounge` capability.
class SvipLoungePage extends ConsumerWidget {
  const SvipLoungePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caps = ref.watch(membershipCapabilitiesSyncProvider);
    if (!caps.allows(MembershipCapabilityKeys.svipLounge)) {
      return Scaffold(
        body: DiscoverBackground(
          child: DiscoverSubPage(
            title: 'SVIP Lounge',
            body: MembershipCapabilityLockedBody(
              capabilityKey: MembershipCapabilityKeys.svipLounge,
              title: 'SVIP Lounge',
              message:
                  'Bu alan yalnızca SVIP üyeler içindir. Üyeliğinizi yükseltin.',
            ),
          ),
        ),
      );
    }

    final roomsAsync = ref.watch(voiceRoomsListNotifierProvider);

    return Scaffold(
      body: DiscoverBackground(
        child: DiscoverSubPage(
          title: 'SVIP Lounge',
          subtitle: 'Elit sesli odalar',
          body: roomsAsync.when(
            loading: () => const Center(child: DiscoverAccentLoader()),
            error: (e, _) => Center(child: Text('$e')),
            data: (rooms) {
              final vip = rooms.where((r) => r.isVipGoldRoom).toList();
              if (vip.isEmpty) {
                return const Center(
                  child: Text('Şu an listelenen VIP oda yok.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: vip.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final room = vip[i];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.amber.withValues(alpha: 0.5),
                      ),
                    ),
                    title: Text(room.nameTr),
                    subtitle: Text(room.slug),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                    onTap: () => openVoiceRoomWithVipGate(context, ref, room),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
