import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/live_room_interaction_provider.dart';

/// Canlı yayın beğeni butonu — optimistic REST + uçan kalp animasyonu.
class LiveLikeButton extends ConsumerStatefulWidget {
  const LiveLikeButton({
    super.key,
    required this.streamId,
    this.width = 70,
  });

  final String streamId;
  final double width;

  @override
  ConsumerState<LiveLikeButton> createState() => _LiveLikeButtonState();
}

class _LiveLikeButtonState extends ConsumerState<LiveLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  final _particles = <_LikeParticle>[];
  final _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() {
    ref.read(liveRoomInteractionProvider(widget.streamId).notifier).burstHearts();
    _addParticle();
    _controller.forward().then((_) => _controller.reverse());
  }

  void _addParticle() {
    final id = DateTime.now().microsecondsSinceEpoch;
    setState(() {
      _particles.add(_LikeParticle(id: id, offsetX: (_rand.nextDouble() - 0.5) * 60));
      if (_particles.length > 8) {
        _particles.removeRange(0, _particles.length - 8);
      }
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _particles.removeWhere((p) => p.id == id));
    });
  }

  /// Uzak izleyiciden gelen beğeni — yalnızca görsel.
  void pulseRemote() {
    _addParticle();
  }

  @override
  Widget build(BuildContext context) {
    final interaction = ref.watch(liveRoomInteractionProvider(widget.streamId));

    return SizedBox(
      width: widget.width,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          ..._particles.map((p) => _FloatingHeart(particle: p)),
          GestureDetector(
            onTap: _onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.pinkAccent,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCount(interaction.likeCount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _LikeParticle {
  _LikeParticle({required this.id, required this.offsetX});

  final int id;
  final double offsetX;
}

class _FloatingHeart extends StatefulWidget {
  const _FloatingHeart({required this.particle});

  final _LikeParticle particle;

  @override
  State<_FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<_FloatingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<double> _position;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_ctrl);

    _position = Tween<double>(begin: 0, end: -120).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 80),
    ]).animate(_ctrl);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Positioned(
        bottom: 60 + _position.value,
        left: 35 + widget.particle.offsetX,
        child: Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.pinkAccent,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

/// Signal polling'den gelen uzak beğenileri işler.
void handleLiveLikeSignal(
  WidgetRef ref, {
  required String streamId,
  required Map<String, dynamic> signal,
}) {
  final type = (signal['type'] ?? signal['event'] ?? '').toString().toLowerCase();
  if (type != 'like' && type != 'streamlike' && type != 'stream_like') return;

  final payload = signal['payload'] is Map
      ? Map<String, dynamic>.from(signal['payload'] as Map)
      : signal;
  final delta = _asInt(payload['count'] ?? payload['delta'] ?? 1);
  final total = _asIntOrNull(payload['likeCount'] ?? payload['total']);
  final userId = (payload['userId'] ?? payload['senderId'] ?? payload['id'])
      ?.toString()
      .trim();
  final userTotal = _asIntOrNull(
    payload['userLikeCount'] ?? payload['userLikes'] ?? payload['myLikes'],
  );

  final notifier = ref.read(liveRoomInteractionProvider(streamId).notifier);
  if (userId != null && userId.isNotEmpty) {
    notifier.applyRemoteUserLike(
      userId: userId,
      delta: delta,
      userTotal: userTotal,
      streamTotal: total,
    );
    return;
  }
  if (total != null) {
    notifier.syncRemoteLikeCount(total, pulse: true);
  } else if (delta > 0) {
    notifier.pulseHeartsVisual(bursts: delta.clamp(1, 3));
  } else {
    notifier.pulseHeartsVisual();
  }
}

int _asInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? 0;
}

int? _asIntOrNull(dynamic v) {
  if (v == null) return null;
  final n = _asInt(v);
  return n > 0 ? n : null;
}
