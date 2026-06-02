import 'package:flutter/material.dart';

import '../voice_room/voice_room_announcement.dart';

/// Duyuru kutusu — site gibi sürekli görünür (kapatılana kadar).
class VoiceRoomPersistentDuyuru extends StatefulWidget {
  const VoiceRoomPersistentDuyuru({
    super.key,
    required this.text,
    this.canEdit = false,
    this.onEdit,
  });

  final String text;
  final bool canEdit;
  final VoidCallback? onEdit;

  @override
  State<VoiceRoomPersistentDuyuru> createState() =>
      _VoiceRoomPersistentDuyuruState();
}

class _VoiceRoomPersistentDuyuruState extends State<VoiceRoomPersistentDuyuru> {
  var _visible = true;

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
