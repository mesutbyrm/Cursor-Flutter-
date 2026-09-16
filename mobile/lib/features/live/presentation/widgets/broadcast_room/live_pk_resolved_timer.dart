import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../voice_hub/domain/pk/pk_battle_remote_models.dart';
import '../../../../pk/presentation/widgets/pk_battle_visuals.dart';

/// Sunucu `endsAt` / `startedAt` ile senkron geri sayım — yalnızca bu widget rebuild olur.
class LivePkResolvedTimer extends StatefulWidget {
  const LivePkResolvedTimer({
    super.key,
    this.remote,
    this.fallbackSeconds = 0,
    this.showPkLabel = true,
    this.centered = true,
    this.onExpired,
  });

  final PkBattleRemote? remote;
  final int fallbackSeconds;
  final bool showPkLabel;
  final bool centered;
  final VoidCallback? onExpired;

  @override
  State<LivePkResolvedTimer> createState() => _LivePkResolvedTimerState();
}

class _LivePkResolvedTimerState extends State<LivePkResolvedTimer> {
  Timer? _tick;
  int _display = 0;
  var _expiredFired = false;

  @override
  void initState() {
    super.initState();
    _sync();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => _sync());
  }

  @override
  void didUpdateWidget(covariant LivePkResolvedTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final remote = widget.remote;
    final next = remote != null
        ? remote.resolvedSecondsLeft()
        : widget.fallbackSeconds.clamp(0, 86400);
    if (next != _display) {
      setState(() => _display = next);
    }
    if (next <= 0 &&
        !_expiredFired &&
        (remote?.isActive == true || widget.fallbackSeconds > 0)) {
      _expiredFired = true;
      widget.onExpired?.call();
    }
    if (next > 0) _expiredFired = false;
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_display <= 0 && widget.remote?.isActive != true) {
      return const SizedBox.shrink();
    }
    final badge = PkBattleTimerBadge(
      secondsLeft: _display,
      flashThreshold: 10,
    );
    if (!widget.showPkLabel) return badge;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.bolt_rounded, color: Color(0xFFFFD54F), size: 18),
        const SizedBox(width: 4),
        const Text(
          'PK',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 8),
        badge,
      ],
    );
    if (!widget.centered) return row;
    return row;
  }
}
