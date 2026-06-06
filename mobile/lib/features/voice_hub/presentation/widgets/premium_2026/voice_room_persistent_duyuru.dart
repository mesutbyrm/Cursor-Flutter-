import 'dart:async';

import 'package:flutter/material.dart';

import '../voice_room/voice_room_announcement.dart';

/// Duyuru kutusu — görünür, 5 saniye sonra kendiliğinden kapanır.
class VoiceRoomPersistentDuyuru extends StatefulWidget {
  const VoiceRoomPersistentDuyuru({
    super.key,
    required this.text,
    this.canEdit = false,
    this.onEdit,
    this.autoDismissSeconds = 5,
  });

  final String text;
  final bool canEdit;
  final VoidCallback? onEdit;
  final int autoDismissSeconds;

  @override
  State<VoiceRoomPersistentDuyuru> createState() =>
      _VoiceRoomPersistentDuyuruState();
}

class _VoiceRoomPersistentDuyuruState extends State<VoiceRoomPersistentDuyuru> {
  var _visible = true;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();
    _scheduleAutoDismiss();
  }

  @override
  void didUpdateWidget(covariant VoiceRoomPersistentDuyuru oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _visible = true;
      _scheduleAutoDismiss();
    }
  }

  void _scheduleAutoDismiss() {
    _autoDismiss?.cancel();
    if (widget.text.trim().isEmpty) return;
    final sec = widget.autoDismissSeconds;
    if (sec <= 0) return;
    _autoDismiss = Timer(Duration(seconds: sec), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || widget.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: VoiceRoomAnnouncement(
        text: widget.text,
        onDismiss: () => setState(() => _visible = false),
      ),
    );
  }
}
