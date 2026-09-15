import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../pk/presentation/widgets/pk_start_sheet.dart';

/// PK daveti — rota uyumluluğu; asıl akış `openVoicePkInviteSheet`.
class PkInvitePage extends ConsumerStatefulWidget {
  const PkInvitePage({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<PkInvitePage> createState() => _PkInvitePageState();
}

class _PkInvitePageState extends ConsumerState<PkInvitePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
  }

  Future<void> _openSheet() async {
    await openVoicePkInviteSheet(context, ref, widget.room);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
