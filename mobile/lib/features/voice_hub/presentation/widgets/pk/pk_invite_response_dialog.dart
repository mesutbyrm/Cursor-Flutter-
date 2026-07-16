import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/pk/pk_invite_expiry.dart';
import 'pk_invite_countdown.dart';

/// PK davet yanıt diyaloğu — 60 sn geri sayım, süre dolunca kapanır.
Future<bool?> showPkInviteResponseDialog({
  required BuildContext context,
  required String challengerLabel,
  String? durationHint,
  DateTime? expiresAt,
  int timeoutSeconds = pkInviteTimeoutSeconds,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _PkInviteResponseDialog(
      challengerLabel: challengerLabel,
      durationHint: durationHint,
      expiresAt: expiresAt,
      timeoutSeconds: timeoutSeconds,
    ),
  );
}

class _PkInviteResponseDialog extends StatefulWidget {
  const _PkInviteResponseDialog({
    required this.challengerLabel,
    this.durationHint,
    this.expiresAt,
    required this.timeoutSeconds,
  });

  final String challengerLabel;
  final String? durationHint;
  final DateTime? expiresAt;
  final int timeoutSeconds;

  @override
  State<_PkInviteResponseDialog> createState() =>
      _PkInviteResponseDialogState();
}

class _PkInviteResponseDialogState extends State<_PkInviteResponseDialog> {
  Timer? _autoClose;
  var _expired = false;

  @override
  void initState() {
    super.initState();
    final left = pkInviteSecondsLeft(
      expiresAt: widget.expiresAt,
      timeoutSeconds: widget.timeoutSeconds,
    );
    if (left > 0) {
      _autoClose = Timer(Duration(seconds: left), () {
        if (!mounted) return;
        setState(() => _expired = true);
        Navigator.of(context).pop(null);
      });
    } else {
      _expired = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(null);
      });
    }
  }

  @override
  void dispose() {
    _autoClose?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hint = widget.durationHint?.trim();
    return AlertDialog(
      backgroundColor: const Color(0xFF1A0F2E),
      title: const Text('PK Daveti', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.challengerLabel} size PK daveti gönderdi.'
            '${hint != null && hint.isNotEmpty ? '\n$hint' : ''}\n'
            'Kabul ediyor musunuz?',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          PkInviteCountdownText(
            expiresAt: widget.expiresAt,
            timeoutSeconds: widget.timeoutSeconds,
            onExpired: () {
              if (!mounted || _expired) return;
              setState(() => _expired = true);
              Navigator.of(context).pop(null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Reddet'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Kabul Et'),
        ),
      ],
    );
  }
}

void showPkInviteExpiredSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(pkInviteExpiredMessage)),
  );
}
