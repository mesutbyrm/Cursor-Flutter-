import 'dart:async';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../../../../core/storage/local_cache.dart';
import '../voice_room/voice_room_announcement.dart';

/// Duyuru — 15 saniye gösterilir; kapatılınca oda+metin anahtarıyla kaydedilir.
class VoiceTimedDuyuru extends StatefulWidget {
  const VoiceTimedDuyuru({
    super.key,
    required this.roomKey,
    required this.text,
  });

  final String roomKey;
  final String text;

  @override
  State<VoiceTimedDuyuru> createState() => _VoiceTimedDuyuruState();
}

class _VoiceTimedDuyuruState extends State<VoiceTimedDuyuru> {
  static const _showDuration = Duration(seconds: 15);

  Timer? _hideTimer;
  var _visible = false;
  var _dismissed = false;

  String get _cacheKey {
    final hash = widget.text.hashCode;
    return 'voice_duyuru_${widget.roomKey}_$hash';
  }

  @override
  void initState() {
    super.initState();
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
    _hideTimer = Timer(_showDuration, () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await LocalCache.setBool(_cacheKey, true);
    _hideTimer?.cancel();
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          VoiceRoomAnnouncement(
            text: widget.text,
            onDismiss: _dismiss,
          ),
          Positioned(
            top: 6,
            right: 44,
            child: _CountdownBadge(
              duration: _showDuration,
              onFinished: () {
                if (mounted) setState(() => _visible = false);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountdownBadge extends StatefulWidget {
  const _CountdownBadge({
    required this.duration,
    required this.onFinished,
  });

  final Duration duration;
  final VoidCallback onFinished;

  @override
  State<_CountdownBadge> createState() => _CountdownBadgeState();
}

class _CountdownBadgeState extends State<_CountdownBadge> {
  late int _secondsLeft;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.duration.inSeconds;
    _tick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        widget.onFinished();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppThemeColors.accentPink.withValues(alpha: 0.5)),
      ),
      child: Text(
        '${_secondsLeft}s',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppThemeColors.accentPink,
        ),
      ),
    );
  }
}
