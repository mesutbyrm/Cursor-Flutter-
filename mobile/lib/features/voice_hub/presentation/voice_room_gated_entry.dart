import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../vip_gold/presentation/widgets/vip_locked_room_sheet.dart';
import '../../../vip_gold/domain/voice_room_access.dart';
import 'basic/voice_room_page.dart';
import 'widgets/voice_room_error_boundary.dart';

/// Derin bağlantı ile gelen odalar — şifre kapısı sonra oda.
class VoiceRoomGatedEntry extends ConsumerStatefulWidget {
  const VoiceRoomGatedEntry({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<VoiceRoomGatedEntry> createState() =>
      _VoiceRoomGatedEntryState();
}

class _VoiceRoomGatedEntryState extends ConsumerState<VoiceRoomGatedEntry> {
  var _ready = false;
  var _denied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runGate());
  }

  Future<void> _runGate() async {
    if (!mounted) return;
    if (widget.room.isPasswordLockedRoom) {
      final ok = await showVipLockedRoomSheet(context, ref, room: widget.room);
      if (!mounted) return;
      if (!ok) {
        setState(() => _denied = true);
        return;
      }
    }
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_denied) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0B12),
        body: Center(
          child: Text(
            'Oda şifresi gerekli',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }
    if (!_ready && widget.room.isPasswordLockedRoom) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0B12),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFB388FF)),
        ),
      );
    }
    final key = widget.room.apiRoomKey.isNotEmpty
        ? widget.room.apiRoomKey
        : widget.room.id;
    return VoiceRoomErrorBoundary(
      roomId: key,
      child: buildVoiceRoomPage(widget.room),
    );
  }
}
