import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../domain/entities/chat_room_presence.dart';
import '../../../../domain/pk/pk_battle_state.dart';
import '../../../theme/voice_room_tokens.dart';
import 'pk_animated_score_bar.dart';

/// Takım savaşı — iki sıra avatar + toplam skor.
class PkTeamBattleStrip extends StatelessWidget {
  const PkTeamBattleStrip({
    super.key,
    required this.state,
  });

  final PkBattleState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _TeamColumn(
              title: 'TAKIM A',
              members: state.left.members,
              total: state.left.total,
              color: VoiceRoomTokens.neonPink,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _TeamColumn(
              title: 'TAKIM B',
              members: state.right.members,
              total: state.right.total,
              color: VoiceRoomTokens.neonBlue,
              alignEnd: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamColumn extends StatelessWidget {
  const _TeamColumn({
    required this.title,
    required this.members,
    required this.total,
    required this.color,
    this.alignEnd = false,
  });

  final String title;
  final List<ChatRoomPresence> members;
  final int total;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: color,
          ),
        ),
        Text(
          PkAnimatedScoreBar.fmt(total),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: color,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: alignEnd ? WrapAlignment.end : WrapAlignment.start,
          children: [
            for (var i = 0; i < members.length.clamp(0, 6); i++)
              _TeamAvatar(user: members[i], color: color),
          ],
        ),
      ],
    );
  }
}

class _TeamAvatar extends StatelessWidget {
  const _TeamAvatar({required this.user, required this.color});

  final ChatRoomPresence user;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final img = user.image;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: VoiceRoomTokens.neonGlow(color, blur: 8),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: color.withValues(alpha: 0.2),
        backgroundImage:
            img != null && img.isNotEmpty ? CachedNetworkImageProvider(img) : null,
        child: img == null || img.isEmpty
            ? Icon(Icons.person, size: 20, color: color)
            : null,
      ),
    );
  }
}
