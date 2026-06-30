import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/voice_room_tokens.dart';

/// Yetkili giriş — koltuk altı sağdan sola kayan bant (tüm kullanıcılar).
class VoiceRoomStaffJoinBanner extends StatefulWidget {
  const VoiceRoomStaffJoinBanner({
    super.key,
    required this.enterBanner,
  });

  final String? enterBanner;

  @override
  State<VoiceRoomStaffJoinBanner> createState() =>
      _VoiceRoomStaffJoinBannerState();
}

class _StaffJoinLine {
  _StaffJoinLine({
    required this.line,
    required this.accent,
  });

  final String line;
  final Color accent;
}

class _VoiceRoomStaffJoinBannerState extends State<VoiceRoomStaffJoinBanner>
    with SingleTickerProviderStateMixin {
  final _queue = <_StaffJoinLine>[];
  final _seen = <String>{};
  _StaffJoinLine? _active;
  AnimationController? _scroll;
  String? _lastBanner;
  double _segmentWidth = 0;

  static const _style = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.2,
  );

  static const _accent = VoiceRoomTokens.gold;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant VoiceRoomStaffJoinBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    _collectFromBanner();
  }

  @override
  void initState() {
    super.initState();
    _collectFromBanner();
  }

  void _collectFromBanner() {
    final banner = widget.enterBanner?.trim();
    if (banner == null || banner.isEmpty || banner == _lastBanner) return;
    _lastBanner = banner;
    final key = banner.toLowerCase();
    if (!_seen.add(key)) return;
    _queue.add(_StaffJoinLine(line: banner, accent: _accent));
    if (_active == null) _showNext();
  }

  Future<void> _showNext() async {
    if (!mounted || _queue.isEmpty) return;
    _active = _queue.removeAt(0);
    _scroll?.dispose();
    _scroll = null;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMarquee());
  }

  void _startMarquee() {
    if (!mounted || _active == null) return;
    final line = _active!.line;
    final painter = TextPainter(
      text: TextSpan(text: line, style: _style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    _segmentWidth = painter.width + 48;
    final viewport = context.size?.width ?? 320;
    final travel = _segmentWidth + viewport;
    final durationMs = (travel * 18).clamp(4500, 14000).round();
    _scroll = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: durationMs),
    );
    _scroll!.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      _active = null;
      _scroll?.dispose();
      _scroll = null;
      if (_queue.isNotEmpty) {
        unawaited(_showNext());
      } else {
        setState(() {});
      }
    });
    _scroll!.forward(from: 0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _collectFromBanner();
    final line = _active;
    if (line == null || _scroll == null) {
      return const SizedBox.shrink();
    }

    final viewport = context.size?.width ?? 320;
    final marquee = AnimatedBuilder(
      animation: _scroll!,
      builder: (context, _) {
        final start = viewport;
        final end = -_segmentWidth;
        final dx = start + (end - start) * _scroll!.value;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Text(line.line, style: _style, maxLines: 1),
        );
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              line.accent.withValues(alpha: 0.42),
              Colors.black.withValues(alpha: 0.82),
            ],
          ),
          border: Border.all(color: line.accent.withValues(alpha: 0.55)),
          boxShadow: VoiceRoomTokens.neonGlow(line.accent, blur: 10),
        ),
        child: SizedBox(
          height: 34,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OverflowBox(
                alignment: Alignment.centerLeft,
                maxWidth: double.infinity,
                child: marquee,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
