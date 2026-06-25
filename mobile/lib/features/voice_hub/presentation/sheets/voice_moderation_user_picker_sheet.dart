import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../utils/voice_moderation_target_color.dart';
import '../utils/voice_room_permissions.dart';

enum VoiceModerationPickerAction { kick, ban, unban }

/// !kick / !ban / !unban — renk kodlu kullanıcı listesi (web parity).
Future<void> showVoiceModerationUserPicker({
  required BuildContext context,
  required WidgetRef ref,
  required VoiceRoomEntity room,
  required VoiceRoomPermissions perms,
  required VoiceModerationPickerAction action,
  required List<ChatRoomPresence> presence,
}) async {
  final roomKey = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
  final auth = ref.read(authControllerProvider).valueOrNull;
  final selfId = auth?.id;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF12082A),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      final title = switch (action) {
        VoiceModerationPickerAction.kick => 'Kullanıcı at (!kick)',
        VoiceModerationPickerAction.ban => 'Kullanıcı banla (!ban)',
        VoiceModerationPickerAction.unban => 'Ban kaldır (!unban)',
      };
      final users = presence
          .where((p) => p.id.isNotEmpty && p.id != selfId)
          .toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              if (action == VoiceModerationPickerAction.unban)
                _UnbanByNameField(roomKey: roomKey)
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final u = users[i];
                      final color = VoiceModerationTargetColorResolver.resolve(
                        actor: perms,
                        target: u,
                        kickAction: action == VoiceModerationPickerAction.kick,
                      );
                      final actionable =
                          VoiceModerationTargetColorResolver.isActionable(color);
                      final border =
                          VoiceModerationTargetColorResolver.valueOf(color);
                      return ListTile(
                        enabled: actionable,
                        leading: CircleAvatar(
                          backgroundColor: border.withValues(alpha: 0.35),
                          backgroundImage: u.image != null && u.image!.isNotEmpty
                              ? NetworkImage(u.image!)
                              : null,
                          child: u.image == null || u.image!.isEmpty
                              ? Text(
                                  u.displayName.isNotEmpty
                                      ? u.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(
                          u.displayName,
                          style: TextStyle(
                            color: actionable ? Colors.white : Colors.white38,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          u.nickname ?? u.chatRole ?? '',
                          style: TextStyle(
                            color: border.withValues(alpha: 0.9),
                            fontSize: 11,
                          ),
                        ),
                        trailing: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: border,
                            shape: BoxShape.circle,
                          ),
                        ),
                        onTap: !actionable
                            ? null
                            : () async {
                                Navigator.pop(ctx);
                                final ctrl = ref.read(
                                  voiceRoomLiveProvider(roomKey).notifier,
                                );
                                if (action == VoiceModerationPickerAction.kick) {
                                  final result = await ctrl.kickUserModeration(
                                    userId: u.id,
                                  );
                                  if (result != null) {
                                    ctrl.showModerationToast(
                                      'Kullanıcı kicklendi',
                                    );
                                  }
                                } else if (action ==
                                    VoiceModerationPickerAction.ban) {
                                  final err = await ctrl.banUserModeration(
                                    userId: u.id,
                                  );
                                  if (err != null && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(err)),
                                    );
                                  }
                                }
                              },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _UnbanByNameField extends ConsumerStatefulWidget {
  const _UnbanByNameField({required this.roomKey});

  final String roomKey;

  @override
  ConsumerState<_UnbanByNameField> createState() => _UnbanByNameFieldState();
}

class _UnbanByNameFieldState extends ConsumerState<_UnbanByNameField> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Banlı kullanıcı adı veya kullanıcı kimliği',
          style: TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'kullaniciadi',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () async {
            final raw = _ctrl.text.trim();
            if (raw.isEmpty) return;
            final live = ref.read(voiceRoomLiveProvider(widget.roomKey));
            String? userId;
            for (final p in live.presence) {
              final keys = [p.id, p.name, p.nickname]
                  .whereType<String>()
                  .map((e) => e.trim().toLowerCase());
              if (keys.any((k) => k == raw.toLowerCase())) {
                userId = p.id;
                break;
              }
            }
            userId ??= raw;
            final err = await ref
                .read(voiceRoomLiveProvider(widget.roomKey).notifier)
                .unbanUserModeration(userId: userId);
            if (!context.mounted) return;
            Navigator.pop(context);
            if (err != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(err)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ban kaldırıldı')),
              );
            }
          },
          child: const Text('Ban kaldır'),
        ),
      ],
    );
  }
}
