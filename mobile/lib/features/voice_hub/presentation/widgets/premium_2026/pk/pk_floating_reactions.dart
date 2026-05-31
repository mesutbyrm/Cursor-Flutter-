import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

/// PK sırasında yüzen kalp / hediye tepkileri.
class PkFloatingReactions extends StatefulWidget {
  const PkFloatingReactions({
    super.key,
    this.burstToken = 0,
    this.enabled = true,
  });

  final int burstToken;
  final bool enabled;

  @override
  State<PkFloatingReactions> createState() => PkFloatingReactionsState();
}

class PkFloatingReactionsState extends State<PkFloatingReactions>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _items = <_Reaction>[];
  final _rand = Random();
  Timer? _ambient;

  static const _pool = ['💖', '🔥', '⭐', '🎁', '👏', '✨'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _ambient = Timer.periodic(const Duration(milliseconds: 1100), (_) {
      if (!widget.enabled || !mounted) return;
      _spawn();
    });
  }

  @override
  void didUpdateWidget(covariant PkFloatingReactions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.burstToken != oldWidget.burstToken) {
      for (var i = 0; i < 6; i++) {
        _spawn(emoji: i.isEven ? '🎁' : '💖');
      }
    }
  }

  void _spawn({String? emoji}) {
    setState(() {
      _items.add(_Reaction(
        id: _rand.nextInt(1 << 30),
        emoji: emoji ?? _pool[_rand.nextInt(_pool.length)],
        x: 0.55 + _rand.nextDouble() * 0.38,
        phase: _rand.nextDouble(),
        fromLeft: _rand.nextBool(),
      ));
      if (_items.length > 18) _items.removeAt(0);
    });
  }

  @override
  void dispose() {
    _ambient?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    final h = MediaQuery.sizeOf(context).height;
    final w = MediaQuery.sizeOf(context).width;

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            children: [
              for (final r in _items)
                Positioned(
                  left: w * (r.fromLeft ? r.x * 0.45 : r.x),
                  bottom: h * 0.22 + ((_ctrl.value + r.phase) % 1.0) * h * 0.45,
                  child: Opacity(
                    opacity: (1 - ((_ctrl.value + r.phase) % 1.0)).clamp(0.0, 1.0),
                    child: Text(
                      r.emoji,
                      style: TextStyle(
                        fontSize: 16 + ((_ctrl.value + r.phase) % 1.0) * 14,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Reaction {
  _Reaction({
    required this.id,
    required this.emoji,
    required this.x,
    required this.phase,
    required this.fromLeft,
  });

  final int id;
  final String emoji;
  final double x;
  final double phase;
  final bool fromLeft;
}
