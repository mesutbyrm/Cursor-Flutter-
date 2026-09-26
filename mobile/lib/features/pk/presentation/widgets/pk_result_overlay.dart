import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/pk_models.dart';

/// `completed` — kazanan / berabere; süre dolunca kapanır.
///
/// [onRematch] verildiğinde rövanş teklifi gösterilir ve kullanıcıya karar
/// vermesi için daha uzun süre tanınır. Kapatma (buton, geri, süre dolması)
/// her durumda [onDismiss] çağırır; biten PK böylece temizlenir ve taraflar
/// normal yayına döner.
class PkResultOverlay extends StatefulWidget {
  const PkResultOverlay({
    super.key,
    required this.battle,
    this.winnerName,
    this.autoCloseSeconds = 5,
    this.rematchCloseSeconds = 15,
    this.onRematch,
    this.onDismiss,
  });

  final PkBattle battle;
  final String? winnerName;
  final int autoCloseSeconds;
  final int rematchCloseSeconds;
  final VoidCallback? onRematch;
  final VoidCallback? onDismiss;

  @override
  State<PkResultOverlay> createState() => _PkResultOverlayState();
}

class _PkResultOverlayState extends State<PkResultOverlay> {
  Timer? _close;
  var _decided = false;

  @override
  void initState() {
    super.initState();
    final seconds = widget.onRematch != null
        ? widget.rematchCloseSeconds
        : widget.autoCloseSeconds;
    _close = Timer(Duration(seconds: seconds), _dismiss);
  }

  @override
  void dispose() {
    _close?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (_decided) return;
    _decided = true;
    _close?.cancel();
    widget.onDismiss?.call();
    if (mounted) Navigator.of(context).maybePop();
  }

  void _rematch() {
    if (_decided) return;
    _decided = true;
    _close?.cancel();
    widget.onRematch?.call();
    if (mounted) Navigator.of(context).maybePop();
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _dismiss();
      },
      child: Material(
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
              const SizedBox(height: 24),
              if (widget.onRematch != null) ...[
                FilledButton.icon(
                  onPressed: _rematch,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Rövanş iste'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _dismiss,
                  child: const Text(
                    'Yayına dön',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ] else
                TextButton(
                  onPressed: _dismiss,
                  child: const Text(
                    'Kapat',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showPkResultOverlay(
  BuildContext context, {
  required PkBattle battle,
  String? winnerName,
  VoidCallback? onRematch,
  VoidCallback? onDismiss,
}) {
  return showDialog<void>(
    context: context,
    // Karar (rövanş / yayına dön) açıkça verilmeli; perdeye dokunup geçmek
    // eski PK'yı temizlenmemiş bırakıyordu.
    barrierDismissible: false,
    builder: (ctx) => PkResultOverlay(
      battle: battle,
      winnerName: winnerName,
      onRematch: onRematch,
      onDismiss: onDismiss,
    ),
  );
}
