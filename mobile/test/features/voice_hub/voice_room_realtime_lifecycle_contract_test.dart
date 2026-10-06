import 'package:canlifal_social/core/network/api_endpoints.dart';
import 'package:canlifal_social/features/trtc/domain/entities/live_join_room_result.dart';
import 'package:canlifal_social/features/trtc/domain/entities/trtc_credentials.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:canlifal_social/features/voice_hub/domain/room_event_scope.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_gift_send_authority.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_room_live_join_mapper.dart';
import 'package:canlifal_social/features/voice_hub/domain/entities/chat_room_sse_event.dart';
import 'package:canlifal_social/features/voice_hub/domain/voice_room_sse_session_guard.dart';
import 'package:canlifal_social/features/voice_hub/presentation/coordinators/room_leave_coordinator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Spec 1–20 lifecycle — birim/contract düzeyi (tam E2E CI/integration ayrı).
void main() {
  group('Spec 1–2 — auth paths & join-room endpoint', () {
    test('production live lifecycle endpoints', () {
      expect(ApiEndpoints.liveJoinRoom, '/api/live/join-room');
      expect(ApiEndpoints.liveLeaveRoom, '/api/live/leave-room');
      expect(ApiEndpoints.liveHeartbeat, '/api/live/heartbeat');
      expect(ApiEndpoints.authMobileRefresh, isNotEmpty);
    });
  });

  group('Spec 3–6 — join-room compound fields', () {
    test('mapper exposes participants, seats, trtc', () {
      const result = LiveJoinRoomResult(
        room: LiveJoinRoomInfo(id: 'room-1'),
        trtc: TrtcCredentials(
          sdkAppId: 20040423,
          userId: 'u1',
          userSig: 'sig',
          roomId: 'trtc-1',
        ),
        participants: [
          LiveJoinParticipant(userId: 'u1', userName: 'A', seatIndex: 1),
        ],
        seats: [LiveJoinSeat(seatIndex: 1, userId: 'u1', isMicOn: true)],
      );
      expect(
        VoiceRoomLiveJoinMapper.participantsToPresence(result.participants),
        hasLength(1),
      );
      expect(VoiceRoomLiveJoinMapper.seatsToSlots(result.seats), hasLength(1));
      expect(result.trtc.isValid, isTrue);
    });
  });

  group('Spec 11 — gift jeton authoritative', () {
    test('totalJeton from backend body', () {
      final spent = VoiceGiftSendAuthority.resolveSpentJeton(
        body: const {'totalJeton': 500, 'quantity': 1},
      );
      expect(spent, 500);
    });
  });

  group('Spec 13 — PK timer from endsAt', () {
    test('resolvedSecondsLeft respects endsAt', () {
      final endsAt = DateTime.now().toUtc().add(const Duration(seconds: 30));
      final battle = PkBattleRemote(
        id: 'pk',
        battleType: 'voice',
        status: 'active',
        challengerScore: 0,
        opponentScore: 0,
        secondsLeft: 999,
        durationSeconds: 300,
        targetScore: 0,
        endsAt: endsAt,
        serverNow: DateTime.now().toUtc().toIso8601String(),
      );
      expect(battle.resolvedSecondsLeft(), lessThanOrEqualTo(30));
    });
  });

  group('Spec 14–17 — leave idempotency', () {
    test('RoomLeaveCoordinator single flight', () async {
      final c = RoomLeaveCoordinator();
      var n = 0;
      await Future.wait([
        c.leave(
          roomId: 'r',
          source: 't',
          steps: [
            () async {
              n++;
              await Future<void>.delayed(const Duration(milliseconds: 30));
            },
          ],
        ),
        c.leave(roomId: 'r', source: 't', steps: [() async => n++]),
      ]);
      expect(n, 1);
    });
  });

  group('Spec 7–10 — SSE lifecycle event types', () {
    test('connected and heartbeat wire types', () {
      expect(chatRoomSseEventTypeFrom('connected'), ChatRoomSseEventType.connected);
      expect(chatRoomSseEventTypeFrom('heartbeat'), ChatRoomSseEventType.heartbeat);
      expect(chatRoomSseEventTypeFrom('ping'), ChatRoomSseEventType.heartbeat);
    });

    test('membership events map to join/leave/presence', () {
      expect(chatRoomSseEventTypeFrom('user_join'), ChatRoomSseEventType.userJoin);
      expect(chatRoomSseEventTypeFrom('userleave'), ChatRoomSseEventType.userLeave);
      expect(chatRoomSseEventTypeFrom('presence'), ChatRoomSseEventType.presence);
    });

    test('music/DJ events for P2 discover patches', () {
      expect(chatRoomSseEventTypeFrom('music_started'), ChatRoomSseEventType.musicStarted);
      expect(chatRoomSseEventTypeFrom('music_stopped'), ChatRoomSseEventType.musicStopped);
      expect(chatRoomSseEventTypeFrom('dj_update'), ChatRoomSseEventType.dj);
    });
  });

  group('Spec 18–19 — cross-room event isolation', () {
    test('room_event_scope rejects foreign roomId', () {
      expect(
        roomEventMatchesActiveRoom(
          {'roomId': 'room-a'},
          'room-b',
        ),
        isFalse,
      );
    });

    test('SSE session guard rejects Room A event on Room B', () {
      expect(
        voiceRoomAcceptsAttachedSseEvent(
          sessionActive: true,
          attachedRoomKey: 'room-b',
          eventRoomKey: 'room-a',
          presenceApiKey: 'room-b',
        ),
        isFalse,
      );
    });
  });
}
