import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../providers/pk_battle_remote_provider.dart';

/// PK daveti — karşı oda seçimi.
class PkInvitePage extends ConsumerStatefulWidget {
  const PkInvitePage({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<PkInvitePage> createState() => _PkInvitePageState();
}

class _PkInvitePageState extends ConsumerState<PkInvitePage> {
  var _loading = false;
  String? _error;

  Future<void> _invite(VoiceRoomEntity opponent) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roomKey = widget.room.apiRoomKey.isNotEmpty
          ? widget.room.apiRoomKey
          : widget.room.id;
      final oppKey =
          opponent.apiRoomKey.isNotEmpty ? opponent.apiRoomKey : opponent.id;
      final battle = await ref.read(pkBattleRemoteProvider.notifier).inviteRoom(
            roomId: roomKey,
            opponentRoomId: oppKey,
          );
      if (!mounted) return;
      if (battle == null) {
        setState(() => _error = 'PK daveti gönderilemedi');
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PK daveti gönderildi. Rakip kabul edince PK başlayacak.',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(voiceRoomsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('PK Daveti')),
      body: roomsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rooms) {
          final others = rooms
              .where((r) => r.id != widget.room.id && r.slug != widget.room.slug)
              .toList();
          if (_error != null) {
            return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
          }
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: others.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final r = others[i];
              return ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white12),
                ),
                leading: CircleAvatar(
                  child: Text(r.icon ?? '🎤'),
                ),
                title: Text(r.displayTitle),
                subtitle: Text('${r.onlineCount} çevrimiçi'),
                trailing: const Icon(Icons.flash_on_rounded),
                onTap: () => _invite(r),
              );
            },
          );
        },
      ),
    );
  }
}
