import 'package:canlifal_social/core/performance/animation_perf.dart';
import 'package:flutter/material.dart';

/// TikTok tarzı yüzen kalpler / emoji parçacıkları — paint-only, setState yok.
class FloatingGiftParticles extends StatefulWidget {
  const FloatingGiftParticles({
    super.key,
    this.emojis = const ['💖', '🌹', '⭐'],
    this.spawnFromGiftId,
  });

  final List<String> emojis;
  final String? spawnFromGiftId;

  @override
  State<FloatingGiftParticles> createState() => FloatingGiftParticlesState();
}

class FloatingGiftParticlesState extends State<FloatingGiftParticles> {
  final _layerKey = GlobalKey<FloatingEmojiPaintLayerState>();

  void burst(String emoji, {int count = 8}) {
    _layerKey.currentState?.burst(emoji, count: count);
  }

  @override
  Widget build(BuildContext context) {
    return FloatingEmojiPaintLayer(
      key: _layerKey,
      emojis: widget.emojis,
    );
  }
}
