import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/pk_models.dart';

/// `completed` — kazanan / berabere; 5 sn sonra kapanır.
class PkResultOverlay extends StatefulWidget {
  const PkResultOverlay({
    super.key,
    required this.battle,
    this.winnerName,
    this.autoCloseSeconds = 5,
  });

  final PkBattle battle;
  final String? winnerName;
  final int autoCloseSeconds;

  @override
  State<PkResultOverlay> createState() => _PkResultOverlayState();
}

class _PkResultOverlayState extends State<PkResultOverlay> {
  Timer? _close;

  @override
  void initState() {
    super.initState();
    _close = Timer(Duration(seconds: widget.autoCloseSeconds), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _close?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draw = widget.battle.isDraw ||
        (widget.battle.winnerId.isEmpty &&
            widget.battle.score1 == widget.battle.score2);
    final title = draw
        ? 'Berabere!'
        : '${widget.winnerName ?? 'Kazanan'} kazandı!';
    final subtitle =
        '${widget.battle.score1} — ${widget.battle.score2}';

    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              draw ? Icons.handshake_outlined : Icons.emoji_events_rounded,
              color: const Color(0xFFFFD700),
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showPkResultOverlay(
  BuildContext context, {
  required PkBattle battle,
  String? winnerName,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => PkResultOverlay(battle: battle, winnerName: winnerName),
  );
}
