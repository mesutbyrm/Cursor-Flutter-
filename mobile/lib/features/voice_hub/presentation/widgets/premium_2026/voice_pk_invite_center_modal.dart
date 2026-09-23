import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/pk/pk_battle_remote_models.dart';

/// Orta ekran PK daveti — 60 sn geri sayım, süre dolunca otomatik kapanır.
Future<bool?> showVoicePkInviteCenterModal({
  required BuildContext context,
  required String challengerLabel,
  required PkBattleRemote battle,
}) {
  final minutes = (battle.durationSeconds / 60).round();
  final durationHint = minutes > 0 ? '$minutes dk' : null;

  return showDialog<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (ctx) => _VoicePkInviteDialogBody(
      challengerLabel: challengerLabel,
      durationHint: durationHint,
      initialCountdown: battle.inviteCountdown(),
    ),
  );
}

class _VoicePkInviteDialogBody extends StatefulWidget {
  const _VoicePkInviteDialogBody({
    required this.challengerLabel,
    required this.durationHint,
    required this.initialCountdown,
  });

  final String challengerLabel;
  final String? durationHint;
  final Duration initialCountdown;

  @override
  State<_VoicePkInviteDialogBody> createState() =>
      _VoicePkInviteDialogBodyState();
}

class _VoicePkInviteDialogBodyState extends State<_VoicePkInviteDialogBody> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialCountdown;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining.inSeconds <= 1) {
        _timer?.cancel();
        Navigator.of(context).pop(null);
        return;
      }
      setState(() {
        _remaining = Duration(seconds: _remaining.inSeconds - 1);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final secs = _remaining.inSeconds.clamp(0, 99);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Material(
          color: const Color(0xFF1A0F2E),
          elevation: 18,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⚔️', style: TextStyle(fontSize: 36)),
                const SizedBox(height: 10),
                const Text(
                  'PK İSTEĞİ',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kalan süre: ${secs}s',
                  style: TextStyle(
                    color: Colors.orange.shade300,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '@${widget.challengerLabel} seninle PK yapmak istiyor.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 14,
                    height: 1.35,
                  ),
                ),
                if (widget.durationHint != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Maç süresi: ${widget.durationHint}',
                    style: TextStyle(
                      color: const Color(0xFFB832FF).withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'REDDET',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFB832FF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'KABUL ET',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
