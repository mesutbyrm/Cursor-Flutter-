import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/chat_room_presence.dart';
import '../providers/chat_room_providers.dart';
import '../theme/voice_room_tokens.dart';
import '../widgets/premium/voice_neon_avatar.dart';

/// `GET /api/chat/rooms/{roomId}/voice` — seste olan kullanıcılar.
Future<void> showVoiceRoomVoiceUsersSheet(
  BuildContext context, {
  required WidgetRef ref,
  required String liveKey,
  void Function(ChatRoomPresence user)? onUserTap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF12082A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _VoiceUsersSheet(
      liveKey: liveKey,
      onUserTap: onUserTap,
    ),
  );
}

class _VoiceUsersSheet extends ConsumerStatefulWidget {
  const _VoiceUsersSheet({
    required this.liveKey,
    this.onUserTap,
  });

  final String liveKey;
  final void Function(ChatRoomPresence user)? onUserTap;

  @override
  ConsumerState<_VoiceUsersSheet> createState() => _VoiceUsersSheetState();
}

class _VoiceUsersSheetState extends ConsumerState<_VoiceUsersSheet> {
  List<ChatRoomPresence> _users = const [];
  var _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ref
        .read(voiceRoomLiveProvider(widget.liveKey).notifier)
        .fetchVoiceConnectedUsers();
    if (mounted) {
      setState(() {
        _users = list;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Seste olanlar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_users.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Şu an ses kanalında kimse yok.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final u = _users[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: VoiceNeonAvatar(url: u.image, size: 40),
                      title: Text(
                        u.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: u.isSpeaking
                          ? const Text(
                              'Konuşuyor',
                              style: TextStyle(
                                color: VoiceRoomTokens.neonBlue,
                                fontSize: 11,
                              ),
                            )
                          : null,
                      trailing: u.isSpeaking
                          ? const Icon(Icons.graphic_eq_rounded,
                              color: VoiceRoomTokens.neonPink, size: 18)
                          : null,
                      onTap: widget.onUserTap == null
                          ? null
                          : () {
                              Navigator.pop(context);
                              widget.onUserTap!(u);
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
