import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/pk_event_log.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../../live/presentation/providers/voice_rooms_list_notifier.dart';
import '../../domain/pk/pk_duration_options.dart';
import '../../domain/pk/pk_guest_user_resolver.dart';
import '../../domain/pk/pk_opponent_room_filter.dart';
import '../providers/chat_room_providers.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../widgets/premium_2026/pk/pk_duration_picker.dart';

/// PK daveti — karşı oda seçimi.
class PkInvitePage extends ConsumerStatefulWidget {
  const PkInvitePage({super.key, required this.room});

  final VoiceRoomEntity room;

  @override
  ConsumerState<PkInvitePage> createState() => _PkInvitePageState();
}

class _PkInvitePageState extends ConsumerState<PkInvitePage> {
  var _loading = false;
  var _inviting = false;
  var _syncing = true;
  var _durationSeconds = pkDefaultDurationSeconds;
  String? _error;

  String get _roomKey =>
      widget.room.apiRoomKey.isNotEmpty ? widget.room.apiRoomKey : widget.room.id;

  String? get _altRoomKey =>
      widget.room.slug != _roomKey ? widget.room.slug : null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(voiceRoomsListNotifierProvider.notifier).refresh());
      _syncRoomPk();
    });
  }

  Future<void> _syncRoomPk() async {
    setState(() {
      _syncing = true;
      _error = null;
    });
    try {
      final remote = ref.read(pkBattleRemoteProvider.notifier);
      await remote.loadRoomBattle(
        _roomKey,
        alternateRoomId: _altRoomKey,
      );
    } catch (_) {}
    if (mounted) setState(() => _syncing = false);
  }

  Future<bool> _resolveStalePkConflict() async {
    final remote = ref.read(pkBattleRemoteProvider.notifier);
    await remote.prepareRoomForInvite(
      roomId: _roomKey,
      alternateRoomId: _altRoomKey,
    );
    final loaded = await remote.loadRoomBattle(
      _roomKey,
      alternateRoomId: _altRoomKey,
    );
    if (loaded != null && loaded.id.isNotEmpty && !loaded.isEnded) {
      await remote.end(
        loaded.id,
        roomId: _roomKey,
        alternateRoomId: _altRoomKey,
      );
      remote.clear();
    }
    return true;
  }

  Future<void> _invite(VoiceRoomEntity opponent) async {
    if (_inviting) return;
    _inviting = true;
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    // Ağ + stale PK temizliği UI thread'i kilitlemesin.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      _inviting = false;
      return;
    }
    PkEventLog.requestStart(roomId: _roomKey, targetId: opponent.id);
    try {
      final remote = ref.read(pkBattleRemoteProvider.notifier);
      await remote.prepareRoomForInvite(
        roomId: _roomKey,
        alternateRoomId: _altRoomKey,
      );

      final oppKey =
          opponent.apiRoomKey.isNotEmpty ? opponent.apiRoomKey : opponent.id;
      if (oppKey.isEmpty || oppKey == _roomKey) {
        setState(() => _error = 'Geçersiz rakip oda seçildi');
        return;
      }
      // Yeni kontrat: davet bir odaya gider — rakip oda kimliği yeterli.
      var guestUserId = resolvePkGuestUserId(ownerId: opponent.ownerId);
      if (guestUserId == null || guestUserId.isEmpty) {
        try {
          final presence = await ref.read(chatRoomRemoteProvider).fetchPresence(
                oppKey,
                alternateKey:
                    opponent.slug != oppKey ? opponent.slug : null,
              );
          guestUserId = resolvePkGuestUserId(presence: presence);
        } catch (_) {}
      }
      if (guestUserId == null || guestUserId.isEmpty) {
        setState(() => _error =
            'Rakip oda sahibi bulunamadı. Rakip odada en az bir yönetici veya '
            'sahip çevrimiçi olmalı.');
        return;
      }
      final battle = await remote.inviteRoom(
        roomId: _roomKey,
        alternateRoomId: _altRoomKey,
        guestUserId: guestUserId,
        opponentRoomId: oppKey,
        durationSeconds: _durationSeconds,
      );
      if (!mounted) return;
      if (battle == null) {
        setState(() => _error =
            'PK daveti gönderilemedi. Oda veya rakip bulunamadı — tekrar deneyin.');
        return;
      }
      PkEventLog.requestSuccess(battleId: battle.id);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'PK daveti gönderildi. Rakip kabul edince PK başlayacak.',
          ),
        ),
      );
      return;
    } catch (e) {
      PkEventLog.error('request', e);
      if (mounted) {
        var msg = ApiException.userMessage(e);
        final lower = msg.toLowerCase();
        if (lower.contains('zaten') && lower.contains('pk')) {
          await _resolveStalePkConflict();
          msg = 'Eski PK kaydı temizlendi. Tekrar davet gönderebilirsiniz.';
        }
        if (msg.contains('404')) {
          msg =
              'PK uç noktası bulunamadı (404). Oda kimliğini kontrol edip tekrar deneyin.';
        }
        setState(() => _error = msg);
      }
    } finally {
      _inviting = false;
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
          final others = filterPkEligibleOpponentRooms(
            rooms,
            excludeRoomKey: _roomKey,
          );

          if (others.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PK için uygun aktif oda bulunamadı.\n'
                      'Yalnızca içinde kullanıcı olan ve sahibi belli odalar listelenir.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _syncing
                          ? null
                          : () => ref.invalidate(voiceRoomsProvider),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Odaları yenile'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: PkDurationPicker(
                  selectedSeconds: _durationSeconds,
                  onChanged: (s) => setState(() => _durationSeconds = s),
                ),
              ),
              const SizedBox(height: 12),
              if (_syncing)
                const LinearProgressIndicator(minHeight: 2),
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
                        if (!_loading)
                          TextButton(
                            onPressed: _syncRoomPk,
                            child: const Text('Yenile'),
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
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final r = others[i];
                    return ListTile(
                      enabled: !_loading && !_syncing,
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
