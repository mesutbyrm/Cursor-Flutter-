import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../domain/entities/voice_room_ban_entry.dart';
import '../providers/chat_room_providers.dart';
import '../utils/voice_moderation_target_color.dart';
import '../utils/voice_room_permissions.dart';
import '../utils/kick_strike_ui.dart';
import '../../domain/entities/chat_room_presence.dart';

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

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF12082A),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      if (action == VoiceModerationPickerAction.unban) {
        return _UnbanBanListSheet(roomKey: roomKey, perms: perms);
      }
      return _KickBanPickerSheet(
        roomKey: roomKey,
        room: room,
        perms: perms,
        action: action,
        presence: presence,
      );
    },
  );
}

class _KickBanPickerSheet extends ConsumerWidget {
  const _KickBanPickerSheet({
    required this.roomKey,
    required this.room,
    required this.perms,
    required this.action,
    required this.presence,
  });

  final String roomKey;
  final VoiceRoomEntity room;
  final VoiceRoomPermissions perms;
  final VoiceModerationPickerAction action;
  final List<ChatRoomPresence> presence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).valueOrNull;
    final selfId = auth?.id;
    final title = action == VoiceModerationPickerAction.kick
        ? 'Kullanıcı at (!kick)'
        : 'Kullanıcı banla (!ban)';
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
                          ? canlifalImageProvider(u.image!)
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
                            Navigator.pop(context);
                            final ctrl = ref.read(
                              voiceRoomLiveProvider(roomKey).notifier,
                            );
                            if (action == VoiceModerationPickerAction.kick) {
                              final result = await ctrl.kickUserModeration(
                                userId: u.id,
                              );
                              if (result != null && context.mounted) {
                                final count = result.kickCount.clamp(1, 3);
                                final strikeColor = KickStrikeUi.colorFor(count);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result.feedbackMessage),
                                    backgroundColor: strikeColor,
                                  ),
                                );
                              }
                            } else {
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
  }
}

class _UnbanBanListSheet extends ConsumerStatefulWidget {
  const _UnbanBanListSheet({required this.roomKey, required this.perms});

  final String roomKey;
  final VoiceRoomPermissions perms;

  @override
  ConsumerState<_UnbanBanListSheet> createState() => _UnbanBanListSheetState();
}

class _UnbanBanListSheetState extends ConsumerState<_UnbanBanListSheet> {
  var _loading = true;
  List<VoiceRoomBanEntry> _bans = const [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final bans = await ref
        .read(voiceRoomLiveProvider(widget.roomKey).notifier)
        .fetchModerationBans();
    if (!mounted) return;
    setState(() {
      _bans = bans;
      _loading = false;
      if (bans.isEmpty) _error = 'Banlı kullanıcı bulunamadı';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Ban kaldır (!unban)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Banlanan kullanıcıları gör',
              style: TextStyle(color: Colors.white60, fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _bans.length,
                  itemBuilder: (context, i) {
                    final ban = _bans[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: ban.imageUrl != null &&
                                ban.imageUrl!.isNotEmpty
                            ? canlifalImageProvider(ban.imageUrl!)
                            : null,
                        child: ban.imageUrl == null || ban.imageUrl!.isEmpty
                            ? Text(
                                ban.displayName.isNotEmpty
                                    ? ban.displayName[0].toUpperCase()
                                    : '?',
                              )
                            : null,
                      ),
                      title: Text(
                        ban.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        ban.reason ?? ban.bannedByName ?? '',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 11,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.lock_open_rounded,
                        color: Color(0xFF22C55E),
                      ),
                      onTap: () async {
                        final err = await ref
                            .read(
                              voiceRoomLiveProvider(widget.roomKey).notifier,
                            )
                            .unbanUserModeration(userId: ban.userId);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        if (err != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(err)),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${ban.displayName} banı kaldırıldı'),
                            ),
                          );
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
  }
}
