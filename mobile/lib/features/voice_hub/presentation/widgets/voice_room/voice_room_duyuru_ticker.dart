import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/voice_room_tokens.dart';
import '../../utils/voice_room_duyuru_access.dart';

/// Faz 10 — koltuk altı kayan duyuru bandı (sağdan sola, 2 geçiş).
class VoiceRoomDuyuruTicker extends StatefulWidget {
  const VoiceRoomDuyuruTicker({
    super.key,
    required this.text,
    this.scrollPasses = VoiceRoomDuyuruAccess.scrollPasses,
    this.ttl = VoiceRoomDuyuruAccess.displayTtl,
    this.onScrollComplete,
  });

  final String text;
  final int scrollPasses;
  final Duration ttl;
  final VoidCallback? onScrollComplete;

  @override
  State<VoiceRoomDuyuruTicker> createState() => _VoiceRoomDuyuruTickerState();
}

class _VoiceRoomDuyuruTickerState extends State<VoiceRoomDuyuruTicker>
    with SingleTickerProviderStateMixin {
  AnimationController? _scroll;
  Timer? _hideTimer;
  var _visible = true;
  double _segmentWidth = 0;
  var _passesDone = 0;

  static const _style = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant VoiceRoomDuyuruTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _scroll?.dispose();
      _scroll = null;
      _hideTimer?.cancel();
      _passesDone = 0;
      setState(() => _visible = true);
      _start();
    }
  }

  void _start() {
    if (widget.text.trim().isEmpty) return;
    if (widget.ttl > Duration.zero) {
      _hideTimer = Timer(widget.ttl, () {
        if (mounted) setState(() => _visible = false);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupScroll());
  }

  void _setupScroll() {
    if (!mounted || widget.text.trim().isEmpty) return;
    final label = '📢 ${widget.text.trim()}';
    final painter = TextPainter(
      text: TextSpan(text: '$label     ', style: _style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    _segmentWidth = painter.width;
    final viewport = context.size?.width ?? 320;
    final needsScroll = _segmentWidth > viewport * 0.45;
    _scroll?.dispose();
    if (!needsScroll) {
      final holdMs = (6000 * widget.scrollPasses).clamp(8000, 16000);
      _hideTimer?.cancel();
      _hideTimer = Timer(Duration(milliseconds: holdMs), () {
        if (!mounted) return;
        setState(() => _visible = false);
        widget.onScrollComplete?.call();
      });
      setState(() {});
      return;
    }
    final durationMs = (_segmentWidth * 28).clamp(6000, 20000).round();
    _scroll = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );
    _scroll!.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      _passesDone++;
      if (_passesDone >= widget.scrollPasses) {
        _scroll!.stop();
        if (mounted) {
          setState(() => _visible = false);
          widget.onScrollComplete?.call();
        }
        return;
      }
      _scroll!.forward(from: 0);
    });
    _scroll!.forward(from: 0);
    setState(() {});
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || widget.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final label = '📢 ${widget.text.trim()}';
    final marquee = _scroll != null
        ? AnimatedBuilder(
            animation: _scroll!,
            builder: (context, _) {
              final dx = -_scroll!.value * _segmentWidth;
              return Transform.translate(
                offset: Offset(dx, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$label     ', style: _style),
                    Text('$label     ', style: _style),
                  ],
                ),
              );
            },
          )
        : Text(label, style: _style, maxLines: 1, overflow: TextOverflow.ellipsis);

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
        height: 34,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              VoiceRoomTokens.gold.withValues(alpha: 0.42),
              VoiceRoomTokens.neonPurple.withValues(alpha: 0.55),
              Colors.black.withValues(alpha: 0.85),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: VoiceRoomTokens.gold.withValues(alpha: 0.55),
          ),
          boxShadow: VoiceRoomTokens.neonGlow(VoiceRoomTokens.gold, blur: 10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const Icon(
                  Icons.campaign_rounded,
                  color: VoiceRoomTokens.gold,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(child: marquee),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
