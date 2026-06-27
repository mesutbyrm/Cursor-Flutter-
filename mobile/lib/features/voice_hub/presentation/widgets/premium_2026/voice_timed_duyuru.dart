import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/storage/local_cache.dart';
import '../voice_room/voice_room_announcement.dart';

/// Duyuru — varsayılan 15 sn; üstte sabit + geri sayım çubuğu (web parity).
class VoiceTimedDuyuru extends StatefulWidget {
  const VoiceTimedDuyuru({
    super.key,
    required this.roomKey,
    required this.text,
    this.ttl = const Duration(seconds: 15),
  });

  final String roomKey;
  final String text;
  final Duration ttl;

  @override
  State<VoiceTimedDuyuru> createState() => _VoiceTimedDuyuruState();
}

class _VoiceTimedDuyuruState extends State<VoiceTimedDuyuru>
    with SingleTickerProviderStateMixin {
  Timer? _hideTimer;
  late AnimationController _progress;
  var _visible = false;
  var _dismissed = false;

  String get _cacheKey {
    final hash = widget.text.hashCode;
    return 'voice_duyuru_${widget.roomKey}_$hash';
  }

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(vsync: this, duration: widget.ttl);
    _init();
  }

  Future<void> _init() async {
    if (widget.text.trim().isEmpty) return;
    final saved = LocalCache.getBool(_cacheKey);
    if (saved) {
      if (mounted) setState(() => _dismissed = true);
      return;
    }
    if (mounted) setState(() => _visible = true);
    _progress.forward(from: 0);
    _hideTimer = Timer(widget.ttl, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await LocalCache.setBool(_cacheKey, true);
    _hideTimer?.cancel();
    _progress.stop();
    if (mounted) {
      setState(() {
        _dismissed = true;
        _visible = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !_visible || widget.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: AnimatedBuilder(
        animation: _progress,
        builder: (context, _) {
          final remaining = (1 - _progress.value).clamp(0.0, 1.0);
          final secondsLeft =
              (widget.ttl.inSeconds * remaining).ceil().clamp(0, 999);
          return VoiceRoomAnnouncement(
            text: widget.text,
            onDismiss: _dismiss,
            progress: remaining,
            autoCloseLabel: secondsLeft > 0 ? '$secondsLeft sn' : null,
          );
        },
      ),
    );
  }
}
