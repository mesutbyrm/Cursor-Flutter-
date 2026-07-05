import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/pk/pk_room_models.dart';
import '../../providers/pk_room_providers.dart';

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

String _clock(int s) {
  final v = s.clamp(0, 359999);
  return '${(v ~/ 60).toString().padLeft(2, '0')}:'
      '${(v % 60).toString().padLeft(2, '0')}';
}

/// PK Faz 2 üst overlay — takım skor çubuğu / guest liderlik + geri sayım +
/// son 30 sn "Final Sprint" + kazanan banner'ı. `pkRoomProvider` ile canlı.
class PkRoomScoreOverlay extends ConsumerWidget {
  const PkRoomScoreOverlay({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(pkRoomProvider(matchId));
    if (match == null || match.mode == PkRoomMode.oneVsOne) {
      return const SizedBox.shrink();
    }
    if (match.isCompleted) return _WinnerBanner(match: match);
    return match.isTeam ? _TeamBar(match: match) : _GuestBoard(match: match);
  }
}

class _TeamBar extends StatelessWidget {
  const _TeamBar({required this.match});
  final PkRoomMatch match;

  @override
  Widget build(BuildContext context) {
    final last = match.isLastCall;
    final total = (match.leftScore + match.rightScore).clamp(1, 1 << 31);
    final leftRatio = match.leftScore / total;

    Widget bar = Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: last ? const Color(0xFFFF4D4D) : const Color(0x33FFFFFF),
          width: last ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (last) ...[
                const Icon(Icons.bolt_rounded, color: Color(0xFFFF6B6B), size: 16),
                const SizedBox(width: 4),
              ],
              Text(
                last ? 'FINAL SPRINT  ${_clock(match.remainingSec)}'
                    : _clock(match.remainingSec),
                style: TextStyle(
                  color: last ? const Color(0xFFFF6B6B) : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 22,
              child: Row(
                children: [
                  Expanded(
                    flex: (leftRatio * 1000).round().clamp(1, 1000),
                    child: Container(
                      color: const Color(0xFFFF3D77),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${match.leftName}  ${_fmt(match.leftScore)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                  Expanded(
                    flex: (1000 - (leftRatio * 1000).round()).clamp(1, 1000),
                    child: Container(
                      color: const Color(0xFF3D7BFF),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text('${_fmt(match.rightScore)}  ${match.rightName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (last) {
      bar = TweenAnimationBuilder<double>(
        key: ValueKey(match.remainingSec),
        tween: Tween(begin: 1.0, end: 1.03),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        builder: (_, s, child) => Transform.scale(scale: s, child: child),
        child: bar,
      );
    }
    return bar;
  }
}

class _GuestBoard extends StatelessWidget {
  const _GuestBoard({required this.match});
  final PkRoomMatch match;

  @override
  Widget build(BuildContext context) {
    final seats = [...match.activeSeats]..sort((a, b) => b.score.compareTo(a.score));
    final top = seats.take(3).toList();
    final last = match.isLastCall;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x66000000),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: last ? const Color(0xFFFF4D4D) : const Color(0x33FFFFFF),
          width: last ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(last ? Icons.bolt_rounded : Icons.timer_rounded,
              size: 15, color: last ? const Color(0xFFFF6B6B) : Colors.white),
          const SizedBox(width: 5),
          Text(_clock(match.remainingSec),
              style: TextStyle(
                  color: last ? const Color(0xFFFF6B6B) : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 12.5)),
          const SizedBox(width: 10),
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < top.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        Text('${i + 1}.',
                            style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontSize: 11,
                                fontWeight: FontWeight.w900)),
                        const SizedBox(width: 3),
                        Text(
                          '${top[i].displayName ?? 'Koltuk ${top[i].seatIndex}'} '
                          '${_fmt(top[i].score)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WinnerBanner extends StatelessWidget {
  const _WinnerBanner({required this.match});
  final PkRoomMatch match;

  String get _text {
    if (match.isTeam) {
      switch ((match.winnerSide ?? '').toLowerCase()) {
        case 'left_win':
          return 'Kazanan: ${match.leftName} 🎉';
        case 'right_win':
          return 'Kazanan: ${match.rightName} 🎉';
        case 'draw':
          return 'Berabere 🤝';
      }
      return match.leftScore == match.rightScore
          ? 'Berabere 🤝'
          : (match.leftScore > match.rightScore
              ? 'Kazanan: ${match.leftName} 🎉'
              : 'Kazanan: ${match.rightName} 🎉');
    }
    final t = match.topSeat;
    return t == null ? 'PK bitti' : 'Kazanan: ${t.displayName ?? 'Koltuk ${t.seatIndex}'} 🎉';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x55FFD54F), Color(0x33FF7043)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xAAFFD54F), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD54F), size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(_text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
