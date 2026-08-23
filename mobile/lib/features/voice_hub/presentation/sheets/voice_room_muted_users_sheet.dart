import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../utils/voice_room_permissions.dart';
import '../widgets/premium/voice_neon_avatar.dart';

/// Sessize alınmış kullanıcı listesi (presence `isMuted`).
Future<void> showVoiceMutedUsersSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String roomKey,
  required List<ChatRoomPresence> presence,
  required VoiceRoomPermissions perms,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF12082A),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => _MutedUsersSheet(
      roomKey: roomKey,
      presence: presence,
      perms: perms,
    ),
  );
}

class _MutedUsersSheet extends ConsumerWidget {
  const _MutedUsersSheet({
    required this.roomKey,
    required this.presence,
    required this.perms,
  });

  final String roomKey;
  final List<ChatRoomPresence> presence;
  final VoiceRoomPermissions perms;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = presence.where((p) => p.isMuted).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    final canUnmute = perms.canMuteUsers || perms.canModerate || perms.isRoomOwner;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Sessize alınmış kullanıcılar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            if (muted.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Sessize alınmış kullanıcı yok.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  itemCount: muted.length,
                  itemBuilder: (context, i) {
                    final u = muted[i];
                    return ListTile(
                      leading: VoiceNeonAvatar(url: u.image, size: 40),
                      title: Text(
                        u.displayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        u.chatRole ?? 'dinleyici',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 11,
                        ),
                      ),
                      trailing: canUnmute
                          ? TextButton(
                              onPressed: () async {
                                final err = await ref
                                    .read(voiceRoomLiveProvider(roomKey).notifier)
                                    .unmuteUserModeration(userId: u.id);
                                if (!context.mounted) return;
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      err ?? '${u.displayName} susturması kaldırıldı',
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Aç'),
                            )
                          : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
