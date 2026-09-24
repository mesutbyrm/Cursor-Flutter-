import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../voice_hub/presentation/theme/voice_room_tokens.dart';
import '../../domain/pk/weekly_broadcaster_competition_models.dart';

/// Haftalık yayıncı yarışması kartı — sağ altta, kapatılabilir.
class WeeklyBroadcasterCompetitionCard extends ConsumerStatefulWidget {
  const WeeklyBroadcasterCompetitionCard({
    Key? key,
    required this.competition,
    this.maxHeight = 280,
    this.maxWidth = 200,
  }) : super(key: key);

  final WeeklyBroadcasterCompetition competition;
  final double maxHeight;
  final double maxWidth;

  @override
  ConsumerState<WeeklyBroadcasterCompetitionCard> createState() =>
      _WeeklyBroadcasterCompetitionCardState();
}

class _WeeklyBroadcasterCompetitionCardState
    extends ConsumerState<WeeklyBroadcasterCompetitionCard> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    if (_collapsed) {
      return SizedBox(
        width: widget.maxWidth,
        child: GestureDetector(
          onTap: () => setState(() => _collapsed = false),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1B4D).withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.expand_less,
                  color: VoiceRoomTokens.neonPurple,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  '📊',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Haftalık',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: widget.maxWidth,
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1B4D).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🏆 Haftalık',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: VoiceRoomTokens.neonPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                ),
                Text(
                  'Yarışma',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _collapsed = true),
            child: Icon(
              Icons.expand_more,
              color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.7),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.competition.winners.isNotEmpty) ...[
            Text(
              'Kazananlar',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: VoiceRoomTokens.neonPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            ..._buildWinners(),
            const SizedBox(height: 12),
          ],
          Text(
            'Top Katılımcılar',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          ..._buildTopParticipants(),
        ],
      ),
    );
  }

  List<Widget> _buildWinners() {
    return widget.competition.winners.take(3).map((winner) {
      final medals = ['🥇', '🥈', '🥉'];
      final medal = (winner.rank > 0 && winner.rank <= 3)
          ? medals[winner.rank - 1]
          : '⭐';
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          '$medal ${winner.displayName ?? 'Anonymous'}\n   ${winner.score} puan',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontSize: 9,
                height: 1.3,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList();
  }

  List<Widget> _buildTopParticipants() {
    return widget.competition.participants.take(5).map((participant) {
      final rank = participant.rank;
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            Text(
              '#$rank',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: VoiceRoomTokens.neonPurple,
                    fontSize: 8,
                  ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                participant.displayName ?? 'Anonymous',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                      fontSize: 8,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${participant.score}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: VoiceRoomTokens.neonPurple,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
