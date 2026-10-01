import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/performance/voice_room_entry_perf.dart';
import '../../../live/presentation/providers/live_pk_invite_signal_provider.dart';
import '../../../../core/network/pk_event_log.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/domain/entities/voice_room_entity.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../data/datasources/pk_battle_remote_datasource.dart';
import '../../domain/pk/pk_battle_remote_models.dart';
import '../../domain/pk/pk_opponent_room_filter.dart';
import '../providers/pk_battle_remote_provider.dart';
import '../providers/voice_room_session_registry.dart';
import '../utils/pk_invite_dialog_helper.dart';
import '../utils/voice_room_session_utils.dart';

/// Sesli oda PK davetleri — oda poll + global davet poll; aktif PK'da yönlendirme.
class VoicePkInviteListener extends ConsumerStatefulWidget {
  const VoicePkInviteListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<VoicePkInviteListener> createState() =>
      _VoicePkInviteListenerState();
}

class _VoicePkInviteListenerState extends ConsumerState<VoicePkInviteListener> {
  final Set<String> _seenRejections = {};
  final Set<String> _openedActivePk = {};
  var _showing = false;
  var _polling = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _showing) return;
      unawaited(_pollPendingInvites());
    });
    Future.microtask(() async {
      await ref.read(voiceRoomsProvider.future);
      if (mounted) unawaited(_pollPendingInvites());
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _onBattleUpdate(PkBattleRemote? battle) {
    if (!mounted || battle == null) return;
    // Oda içi PK ne davettir ne de ayrı sayfadır (kompakt panel gösterir).
    if (battle.isInRoomUser) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    if (battle.isActive && !battle.isEnded) {
      unawaited(_maybeOpenActivePkScreen(battle, user.id));
      return;
    }

    if (_showing) return;

    if (battle.isPending) {
      var room = resolvePkInviteTargetRoom(ref, battle, user.id);
      final activeKey = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
      VoiceRoomEntity? activeRoom;
      if (activeKey.isNotEmpty) {
        activeRoom = ref.read(voiceRoomByIdProvider(activeKey)).valueOrNull;
      }
      if (room == null &&
          isPkInviteRecipientInActiveRoom(
            battle,
            activeRoom,
            userId: user.id,
          )) {
        room = activeRoom;
      }
      if (room == null) {
        final oppRoomId = battle.opponentVoiceRoomId?.trim() ?? '';
        if (oppRoomId.isEmpty &&
            battle.voiceRoomId?.trim().isEmpty == true) {
          // Davet yalnızca kullanıcı kimliği ile (GET /pk/me/invites) — sahip olunan oda.
          final owned = ref.read(myOwnedVoiceRoomsProvider);
          for (final r in owned) {
            if (isPkInviteTarget(battle, r, userId: user.id)) {
              room = r;
              break;
            }
          }
        }
        if (room == null) {
          if (battle.voiceRoomId?.trim().isEmpty == true &&
              battle.opponentVoiceRoomId?.trim().isEmpty == true) {
            PkEventLog.error(
              'invite_missing_rooms',
              'PK davetinde room1/room2 (voiceRoomId) yok — backend response doğrulanmalı',
            );
            return;
          }
          // Hedef oda yerel oda listesinde yok (liste eski/filtreli): odayı
          // sunucudan id ile çekip daveti yine göster.
          unawaited(_showInviteForUnlistedRoom(battle, user.id));
          return;
        }
      }
      final recipient = isPkInviteTarget(battle, room, userId: user.id) ||
          isPkInviteRecipientInActiveRoom(battle, room, userId: user.id);
      if (!recipient) return;
      if (isPkChallengerRoom(battle, room)) return;
      final inviteId = battle.effectiveId;
      if (inviteId.isNotEmpty) {
        PkEventLog.incomingRequest(inviteId: inviteId);
        unawaited(_showInviteDialog(battle, room));
      }
      return;
    }

    if (battle.status == 'rejected') {
      final id = battle.effectiveId;
      if (id.isEmpty || !_seenRejections.add(id)) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${pkChallengerRoomLabel(ref, battle)} odası isteğinizi reddetti',
            ),
          ),
        );
      }
      ref.read(pkBattleRemoteProvider.notifier).clear();
    }
  }

  Future<void> _showInviteForUnlistedRoom(
    PkBattleRemote battle,
    String userId,
  ) async {
    final targetId = battle.opponentVoiceRoomId?.trim() ?? '';
    if (targetId.isEmpty || _showing) return;
    try {
      final room = await ref.read(voiceRoomByIdProvider(targetId).future);
      if (!mounted || room == null) return;
      if (!isPkInviteTarget(battle, room, userId: userId)) return;
      if (isPkChallengerRoom(battle, room)) return;
      final inviteId = battle.effectiveId;
      if (inviteId.isEmpty) return;
      PkEventLog.incomingRequest(inviteId: inviteId);
      await _showInviteDialog(battle, room);
    } catch (_) {}
  }

  Future<void> _maybeOpenActivePkScreen(
    PkBattleRemote battle,
    String userId,
  ) async {
    final battleKey = battle.effectiveId;
    if (battleKey.isEmpty || !_openedActivePk.add(battleKey)) return;

    VoiceRoomEntity? room;
    final activeKey = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
    if (activeKey.isNotEmpty) {
      final activeRoom =
          ref.read(voiceRoomByIdProvider(activeKey)).valueOrNull;
      if (activeRoom != null && pkBattleBelongsToRoom(battle, activeRoom)) {
        room = activeRoom;
      }
    }
    room ??= resolvePkInviteTargetRoom(ref, battle, userId);
    if (room == null) {
      for (final r in ref.read(myOwnedVoiceRoomsProvider)) {
        if (pkBattleBelongsToRoom(battle, r)) {
          room = r;
          break;
        }
      }
    }
    if (room == null) {
      _openedActivePk.remove(battleKey);
      return;
    }

    final nav = rootNavigatorKey.currentContext;
    if (nav == null || !nav.mounted) {
      _openedActivePk.remove(battleKey);
      return;
    }
    final router = GoRouter.of(nav);
    final roomKey =
        room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (path.contains('/voice-room/$roomKey/pk')) return;

    await prepareVoiceRoomSwitch(
      ref,
      nextLiveKey: roomKey,
      source: 'pk_active_sse',
    );
    if (!nav.mounted) return;
    VoiceRoomEntryPerf.prewarmOnRoomTap(ref, room);
    GoRouter.of(nav).push('/voice-room/$roomKey/pk', extra: room);
  }

  Future<void> _showInviteDialog(
    PkBattleRemote battle,
    VoiceRoomEntity room,
  ) async {
    if (!mounted || _showing) return;
    _showing = true;
    try {
      final nav = rootNavigatorKey.currentContext ?? context;
      await showPkInviteDialog(nav, ref, battle: battle, room: room);
    } finally {
      _showing = false;
    }
  }

  Future<void> _pollOwnedRooms(
    String userId,
    String? username,
    String activeKey,
    VoiceRoomEntity? activeRoom,
    PkBattleRemoteDataSource api,
  ) async {
    final owned = ref.read(myOwnedVoiceRoomsProvider);
    final allRooms = ref.read(voiceRoomsProvider).valueOrNull ?? const [];
    final ownedKeys = <String>{
      for (final r in owned)
        if (r.apiRoomKey.isNotEmpty) r.apiRoomKey else r.id,
    };
    final extraOwned = allRooms.where((r) {
      final key = r.apiRoomKey.isNotEmpty ? r.apiRoomKey : r.id;
      if (key.isEmpty || ownedKeys.contains(key)) return false;
      return isUserOwnedVoiceRoom(
        r,
        userId: userId,
        username: username,
      );
    });
    final seen = <String>{};
    for (final room in [...owned, ...extraOwned]) {
      final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
      if (key.isEmpty || !seen.add(key)) continue;
      if (key == activeKey) continue;
      final battle = await api.fetchRoomBattle(
        key,
        alternateRoomId: room.slug != key ? room.slug : null,
      );
      if (battle != null && !battle.isEnded) {
        _ingestBattleIfRelevant(battle, activeKey, activeRoom, userId);
        _onBattleUpdate(battle);
        if (battle.isPending || battle.isActive) return;
      }
    }
  }

  void _ingestBattleIfRelevant(
    PkBattleRemote battle,
    String activeKey,
    VoiceRoomEntity? activeRoom,
    String userId,
  ) {
    if (activeKey.isEmpty || activeRoom == null) {
      ref.read(pkBattleRemoteProvider.notifier).ingestSseBattle(battle);
      return;
    }
    if (pkBattleBelongsToRoom(battle, activeRoom) ||
        (battle.isPending &&
            isPkInviteTarget(battle, activeRoom, userId: userId))) {
      ref.read(pkBattleRemoteProvider.notifier).ingestSseBattle(battle);
    }
  }

  Future<void> _pollPendingInvites({bool force = false}) async {
    if (_showing || _polling || !mounted) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;
    final deferOwned =
        !force &&
            ref.read(pkBattleRemoteProvider.notifier).deferVoicePkInviteRestPoll();
    // Yavaş ağda önceki tur bitmeden yenisi başlamasın (istek yığılması).
    _polling = true;
    try {
      final api = ref.read(pkBattleRemoteDataSourceProvider);
      final roomsAsync = ref.read(voiceRoomsProvider);
      if (!roomsAsync.hasValue) {
        await ref.read(voiceRoomsProvider.future);
      }

      final activeKey = ref.read(voiceRoomActiveLiveKeyProvider)?.trim() ?? '';
      // Not: "Odalarım" boşsa yoklamayı atlamak, sahipliği listeden tespit
      // edilemeyen kullanıcıda `/pk/me/invites` kontrolünü de atlatıyor ve
      // davet hiç görünmüyordu. Davet listesi odaya bağlı değildir; her turda
      // sorulur.
      VoiceRoomEntity? activeRoom;
      if (activeKey.isNotEmpty) {
        activeRoom = ref.read(voiceRoomByIdProvider(activeKey)).valueOrNull;
      }

      if (activeKey.isNotEmpty) {
        final alt = activeRoom != null &&
                activeRoom.slug.isNotEmpty &&
                activeRoom.slug != activeKey
            ? activeRoom.slug
            : null;
        final roomBattle = await api.fetchRoomBattle(
          activeKey,
          alternateRoomId: alt,
        );
        if (roomBattle != null && !roomBattle.isEnded) {
          if (activeRoom != null &&
              roomBattle.isPending &&
              !isPkChallengerRoom(roomBattle, activeRoom)) {
            ref
                .read(pkBattleRemoteProvider.notifier)
                .ingestSseBattle(roomBattle);
          } else {
            _ingestBattleIfRelevant(
              roomBattle,
              activeKey,
              activeRoom,
              user.id,
            );
          }
          _onBattleUpdate(roomBattle);
        }
      }

      if (!deferOwned) {
        await _pollOwnedRooms(
          user.id,
          user.username,
          activeKey,
          activeRoom,
          api,
        );
      }

      final invites = await api.fetchMyInvites(forceRefresh: force);
      for (final battle in invites) {
        if (battle.isEnded || !battle.isPending) continue;
        _ingestBattleIfRelevant(
          battle,
          activeKey,
          activeRoom,
          user.id,
        );
        _onBattleUpdate(battle);
        if (battle.isPending) return;
      }
    } catch (e, st) {
      PkEventLog.apiFailure(
        method: 'GET',
        url: 'pk_poll',
        responseBody: e.toString(),
      );
      assert(() {
        debugPrint('[PK] poll error: $e\n$st');
        return true;
      }());
    } finally {
      _polling = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PkBattleRemote?>(pkBattleRemoteProvider, (_, next) {
      _onBattleUpdate(next);
    });
    ref.listen<int>(livePkInviteSignalProvider, (_, __) {
      unawaited(_pollPendingInvites(force: true));
    });
    return widget.child;
  }
}
