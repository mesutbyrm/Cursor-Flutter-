import 'package:canlifal_social/core/performance/list_perf.dart';
import 'package:flutter/material.dart';

import 'package:canlifal_social/core/widgets/user_avatar.dart';

import '../../../domain/entities/chat_room_presence.dart';
import '../../theme/voice_room_tokens.dart';
import '../../utils/voice_room_mention.dart';

/// Faz 11 — @ yazılınca oda kullanıcıları listesi.
class VoiceRoomMentionSuggestions extends StatelessWidget {
  const VoiceRoomMentionSuggestions({
    super.key,
    required this.users,
    required this.onPick,
  });

  final List<ChatRoomPresence> users;
  final ValueChanged<ChatRoomPresence> onPick;

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 8,
      color: const Color(0xFF1A1028).withValues(alpha: 0.98),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.45),
          ),
        ),
        child: SizedBox(
          height: ListPerf.nestedListHeight(
            itemCount: users.length,
            itemExtent: 52,
            separatorExtent: 1,
          ).clamp(52, 220),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: users.length,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            itemBuilder: (context, i) {
              final user = users[i];
              final handle = VoiceRoomMention.handleFor(user);
              return ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: UserAvatar(url: user.image, radius: 16),
                title: Text(
                  user.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  '@$handle',
                  style: TextStyle(
                    color: VoiceRoomTokens.neonBlue.withValues(alpha: 0.9),
                    fontSize: 11,
                  ),
                ),
                onTap: () => onPick(user),
              );
            },
          ),
        ),
      ),
    );
  }
}
