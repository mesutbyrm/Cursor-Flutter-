import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
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

  String get _roomKey =>
      widget.room.apiRoomKey.isNotEmpty ? widget.room.apiRoomKey : widget.room.id;

  Future<void> _invite(VoiceRoomEntity opponent) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final oppKey =
          opponent.apiRoomKey.isNotEmpty ? opponent.apiRoomKey : opponent.id;
      if (oppKey.isEmpty || oppKey == _roomKey) {
        setState(() => _error = 'Geçersiz rakip oda seçildi');
        return;
      }
      final remote = ref.read(pkBattleRemoteProvider.notifier);
      final battle = await remote.inviteRoom(
        roomId: _roomKey,
        opponentRoomId: oppKey,
      );
      if (!mounted) return;
      if (battle == null) {
        setState(() => _error = 'PK daveti gönderilemedi — sunucu yanıt vermedi');
        return;
      }
      remote.connectSocket(
        roomId: _roomKey,
        alternateRoomId: widget.room.slug != _roomKey ? widget.room.slug : null,
        battleId: battle.id,
      );
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
      if (mounted) setState(() => _error = ApiException.userMessage(e));
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
        error: (e, _) => Center(child: Text(ApiException.userMessage(e))),
        data: (rooms) {
          final others = rooms.where((r) {
            final key = r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
            return key.isNotEmpty && key != _roomKey;
          }).toList();

          if (others.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'PK için uygun başka oda bulunamadı.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return Column(
            children: [
              if (_error != null)
                Material(
                  color: Colors.red.withValues(alpha: 0.12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_loading)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: others.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = others[i];
                    return ListTile(
                      enabled: !_loading,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.white12),
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
