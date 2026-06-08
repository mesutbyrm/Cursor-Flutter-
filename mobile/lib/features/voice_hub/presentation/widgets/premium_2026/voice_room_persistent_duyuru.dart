import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/storage/local_cache.dart';
import '../voice_room/voice_room_announcement.dart';

/// Duyuru — günde bir kez, 5 sn sonra kapanır, alt progress çubuğu.
class VoiceRoomPersistentDuyuru extends StatefulWidget {
  const VoiceRoomPersistentDuyuru({
    super.key,
    required this.roomKey,
    required this.text,
    this.canEdit = false,
    this.onEdit,
    this.autoDismissSeconds = 5,
  });

  final String roomKey;
  final String text;
  final bool canEdit;
  final VoidCallback? onEdit;
  final int autoDismissSeconds;

  @override
  State<VoiceRoomPersistentDuyuru> createState() =>
      _VoiceRoomPersistentDuyuruState();
}

class _VoiceRoomPersistentDuyuruState extends State<VoiceRoomPersistentDuyuru> {
  var _visible = false;
  var _dismissed = false;
  Timer? _autoDismiss;
  Timer? _progressTick;
  var _elapsedMs = 0;

  String get _dailyCacheKey {
    final now = DateTime.now();
    final day = '${now.year}-${now.month}-${now.day}';
    return 'voice_duyuru_daily_${widget.roomKey}_$day';
  }

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(_init);
  }

  @override
  void didUpdateWidget(covariant VoiceRoomPersistentDuyuru oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.roomKey != widget.roomKey) {
      scheduleMicrotask(_init);
    }
  }

  Future<void> _init() async {
    _autoDismiss?.cancel();
    _progressTick?.cancel();
    if (widget.text.trim().isEmpty) {
      if (mounted) setState(() => _visible = false);
      return;
    }
    final seenToday = LocalCache.getBool(_dailyCacheKey) == true;
    if (seenToday) {
      if (mounted) {
        setState(() {
          _dismissed = true;
          _visible = false;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _visible = true;
        _dismissed = false;
        _elapsedMs = 0;
      });
    }
    final totalMs = widget.autoDismissSeconds * 1000;
    _progressTick = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) return;
      _elapsedMs += 100;
      if (_elapsedMs >= totalMs) {
        t.cancel();
        return;
      }
      setState(() {});
    });
    _autoDismiss = Timer(Duration(seconds: widget.autoDismissSeconds), () async {
      await LocalCache.setBool(_dailyCacheKey, true);
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _progressTick?.cancel();
    super.dispose();
  }

  Future<void> _dismiss() async {
    await LocalCache.setBool(_dailyCacheKey, true);
    _autoDismiss?.cancel();
    _progressTick?.cancel();
    if (mounted) setState(() => _visible = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed || !_visible || widget.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    final totalMs = widget.autoDismissSeconds * 1000;
    final progress = totalMs > 0 ? (_elapsedMs / totalMs).clamp(0.0, 1.0) : 0.0;
    final secsLeft = ((totalMs - _elapsedMs) / 1000).ceil().clamp(0, 99);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: VoiceRoomAnnouncement(
        text: widget.text,
        onDismiss: _dismiss,
        onEdit: widget.canEdit ? widget.onEdit : null,
        progress: 1 - progress,
        autoCloseLabel: '$secsLeft sn sonra kapanacak',
      ),
    );
  }
}
