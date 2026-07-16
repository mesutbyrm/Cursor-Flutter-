import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../domain/pk/pk_invite_expiry.dart';

/// PK daveti geri sayımı — SSE `expiresAt` / `timeoutSeconds`.
class PkInviteCountdownText extends StatefulWidget {
  const PkInviteCountdownText({
    super.key,
    required this.expiresAt,
    this.timeoutSeconds = pkInviteTimeoutSeconds,
    this.onExpired,
    this.style,
  });

  final DateTime? expiresAt;
  final int timeoutSeconds;
  final VoidCallback? onExpired;
  final TextStyle? style;

  @override
  State<PkInviteCountdownText> createState() => _PkInviteCountdownTextState();
}

class _PkInviteCountdownTextState extends State<PkInviteCountdownText> {
  Timer? _timer;
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    _secondsLeft = pkInviteSecondsLeft(
      expiresAt: widget.expiresAt,
      timeoutSeconds: widget.timeoutSeconds,
    );
    _armTimer();
  }

  @override
  void didUpdateWidget(covariant PkInviteCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt ||
        oldWidget.timeoutSeconds != widget.timeoutSeconds) {
      _secondsLeft = pkInviteSecondsLeft(
        expiresAt: widget.expiresAt,
        timeoutSeconds: widget.timeoutSeconds,
      );
      _armTimer();
    }
  }

  void _armTimer() {
    _timer?.cancel();
    if (_secondsLeft <= 0) {
      widget.onExpired?.call();
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = pkInviteSecondsLeft(
        expiresAt: widget.expiresAt,
        timeoutSeconds: widget.timeoutSeconds,
      );
      setState(() => _secondsLeft = next);
      if (next <= 0) {
        _timer?.cancel();
        widget.onExpired?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'Kalan süre: ${pkInviteCountdownLabel(_secondsLeft)}',
      style: widget.style ??
          const TextStyle(
            color: Color(0xFFFFD54F),
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
    );
  }
}
