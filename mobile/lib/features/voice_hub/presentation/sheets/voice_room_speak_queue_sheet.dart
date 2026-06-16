import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_glass.dart';

/// Moderatör — el kaldıran / dinleyici kuyruğu (web: konuşmacı sırası).
void showVoiceSpeakQueueSheet(
  BuildContext context,
  WidgetRef ref, {
  required VoiceRoomEntity room,
  required VoiceRoomLiveState live,
  required VoiceRoomPermissions perms,
}) {
  if (!perms.canAssignSeats && !perms.isRoomOwner && !perms.isSiteAdmin) {
    return;
  }

  final onStage = live.presence
      .where((p) => p.seatIndex != null && p.seatIndex! >= 0)
      .map((p) => p.id)
      .toSet();
  final occupiedSeats = live.presence
      .map((p) => p.seatIndex)
      .whereType<int>()
      .toSet();
  final listeners = live.presence.where((p) => !onStage.contains(p.id)).toList();

  int? firstFreeSeat() {
    for (var i = 2; i <= 11; i++) {
      if (!occupiedSeats.contains(i)) return i;
    }
    return null;
  }

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scroll) => VoiceGlass(
        borderRadius: 24,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Konuşmacı sırası',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              '${listeners.length} dinleyici — koltuk atayarak sahneye alın',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: listeners.isEmpty
                  ? Center(
                      child: Text(
                        'Bekleyen dinleyici yok',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scroll,
                      itemCount: listeners.length,
                      itemBuilder: (_, i) {
                        final p = listeners[i];
                        return _ListenerTile(
                          user: p,
                          onAssign: () async {
                            final seat = firstFreeSeat();
                            if (seat == null) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Boş koltuk yok'),
                                  ),
                                );
                              }
                              return;
                            }
                            final ctrl = ref
                                .read(voiceRoomLiveProvider(room.liveKey).notifier);
                            final err = await ctrl.assignSeat(
                              seatIndex: seat,
                              userId: p.id,
                            );
                            if (context.mounted && err != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(err)),
                              );
                            }
                          },
                          onDj: perms.canManageDj
                              ? () async {
                                  final ctrl = ref.read(
                                    voiceRoomLiveProvider(room.liveKey).notifier,
                                  );
                                  final err = await ctrl.addRoomDj(p.id);
                                  if (context.mounted && err != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(err)),
                                    );
                                  }
                                }
                              : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ListenerTile extends StatelessWidget {
  const _ListenerTile({
    required this.user,
    required this.onAssign,
    this.onDj,
  });

  final ChatRoomPresence user;
  final VoidCallback onAssign;
  final VoidCallback? onDj;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundImage:
            user.image != null && user.image!.isNotEmpty
                ? NetworkImage(user.image!)
                : null,
        child: user.image == null || user.image!.isEmpty
            ? const Icon(Icons.person)
            : null,
      ),
      title: Text(user.displayName),
      subtitle: user.chatRole != null
          ? Text(user.chatRole!, style: const TextStyle(fontSize: 11))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onDj != null)
            IconButton(
              tooltip: 'DJ yap',
              icon: const Icon(Icons.headphones_rounded, size: 20),
              onPressed: onDj,
            ),
          FilledButton.tonal(
            onPressed: onAssign,
            child: const Text('Ses ver'),
          ),
        ],
      ),
    );
  }
}
