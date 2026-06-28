import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/voice_room_tokens.dart';
import '../../utils/voice_room_duyuru_access.dart';

/// Faz 10 — üst kayan duyuru bandı (tüm kullanıcılar görür).
class VoiceRoomDuyuruTicker extends StatefulWidget {
  const VoiceRoomDuyuruTicker({
    super.key,
    required this.text,
    this.ttl = VoiceRoomDuyuruAccess.displayTtl,
  });

  final String text;
  final Duration ttl;

  @override
  State<VoiceRoomDuyuruTicker> createState() => _VoiceRoomDuyuruTickerState();
}

class _VoiceRoomDuyuruTickerState extends State<VoiceRoomDuyuruTicker>
    with SingleTickerProviderStateMixin {
  AnimationController? _scroll;
  Timer? _hideTimer;
  var _visible = true;
  double _segmentWidth = 0;

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
      setState(() => _visible = true);
      _start();
    }
  }

  void _start() {
    if (widget.text.trim().isEmpty) return;
    _hideTimer = Timer(widget.ttl, () {
      if (mounted) setState(() => _visible = false);
    });
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
    final needsScroll = _segmentWidth > viewport * 0.55;
    _scroll?.dispose();
    if (!needsScroll) {
      setState(() {});
      return;
    }
    final durationMs = (_segmentWidth * 28).clamp(8000, 24000).round();
    _scroll = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    )..repeat();
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
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
        height: 36,
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
