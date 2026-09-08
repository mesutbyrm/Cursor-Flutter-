import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../voice_hub/presentation/providers/chat_room_providers.dart';

/// Admin — sesli oda mini yönetim (odaya gir + kullanıcı at).
Future<void> showAdminVoiceRoomMiniPanel({
  required BuildContext context,
  required WidgetRef ref,
  required VoiceRoomEntity room,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF1A0F2E),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _Panel(room: room),
  );
}

class _Panel extends ConsumerStatefulWidget {
  const _Panel({required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<_Panel> createState() => _PanelState();
}

class _PanelState extends ConsumerState<_Panel> {
  final _userIdCtrl = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _userIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _kick() async {
    final userId = _userIdCtrl.text.trim();
    if (userId.isEmpty) return;
    final roomKey =
        widget.room.apiRoomKey.isNotEmpty ? widget.room.apiRoomKey : widget.room.id;
    setState(() => _busy = true);
    try {
      await ref.read(chatRoomRemoteProvider).kickUser(
            roomKey: roomKey,
            userId: userId,
            reason: 'admin',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kullanıcı odadan atıldı')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.userMessage(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        20 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            room.nameTr.isNotEmpty ? room.nameTr : 'Sesli Oda',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Oda ID: ${room.id}',
            style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              context.push('/voice-room/${room.id}', extra: room);
            },
            icon: const Icon(Icons.meeting_room_outlined),
            label: const Text('Odaya gir'),
          ),
          const SizedBox(height: 14),
          const Text(
            'Kullanıcıyı odadan at',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _userIdCtrl,
            decoration: const InputDecoration(
              labelText: 'Kullanıcı ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _busy ? null : _kick,
            style: FilledButton.styleFrom(
              backgroundColor: AppThemeColors.liveRed,
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('At (kick)'),
          ),
        ],
      ),
    );
  }
}
