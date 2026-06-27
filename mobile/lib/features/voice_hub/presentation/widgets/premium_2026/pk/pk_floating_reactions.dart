import 'package:canlifal_social/core/performance/animation_perf.dart';
import 'package:flutter/material.dart';

/// PK sırasında yüzen kalp / hediye tepkileri — paint-only.
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

class PkFloatingReactionsState extends State<PkFloatingReactions> {
  final _layerKey = GlobalKey<FloatingEmojiPaintLayerState>();

  static const _pool = ['💖', '🔥', '⭐', '🎁', '👏', '✨'];

  @override
  void didUpdateWidget(covariant PkFloatingReactions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.burstToken != oldWidget.burstToken) {
      for (var i = 0; i < 6; i++) {
        _layerKey.currentState?.burst(i.isEven ? '🎁' : '💖');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingEmojiPaintLayer(
      key: _layerKey,
      emojis: _pool,
      enabled: widget.enabled,
      ambientInterval: const Duration(milliseconds: 1100),
      maxParticles: 18,
      bottomFraction: 0.22,
      heightFraction: 0.45,
    );
  }
}
