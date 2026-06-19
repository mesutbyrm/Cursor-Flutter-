import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:canlifal_social/features/home/data/live_fortune_session_store.dart';
import 'package:canlifal_social/features/home/domain/entities/live_fortune_session_entity.dart';
import 'package:canlifal_social/features/home/domain/entities/live_fortune_teller_entity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LiveFortuneSessionStore', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('save and load round-trip', () async {
      const session = LiveFortuneSessionEntity(
        sessionId: 'fs-test-1',
        teller: LiveFortuneTellerEntity(
          id: 'ft-1',
          userId: 'user-teller',
          name: 'Deneme',
          isOnline: true,
          pricePerMinute: 10,
        ),
        durationMinutes: 10,
        totalJeton: 100,
        tellerUserId: 'user-teller',
        clientId: 'user-client',
        isClient: true,
        trtcRoomIdOverride: 'room_fs-test-1',
      );

      await LiveFortuneSessionStore.save(session);
      final loaded = await LiveFortuneSessionStore.load();

      expect(loaded, isNotNull);
      expect(loaded!.sessionId, 'fs-test-1');
      expect(loaded.trtcRoomId, 'room_fs-test-1');
      expect(loaded.teller.name, 'Deneme');
    });

    test('clear removes stored session', () async {
      const session = LiveFortuneSessionEntity(
        sessionId: 'fs-test-2',
        teller: LiveFortuneTellerEntity(id: 'ft-2', name: 'Falcı'),
        durationMinutes: 5,
        totalJeton: 50,
      );
      await LiveFortuneSessionStore.save(session);
      await LiveFortuneSessionStore.clear();
      expect(await LiveFortuneSessionStore.load(), isNull);
    });
  });

  group('LiveFortuneSessionEntity.remotePeerIdFor', () {
    const teller = LiveFortuneTellerEntity(
      id: 'ft-1',
      userId: 'user-teller',
      name: 'Deneme',
    );
    const clientSession = LiveFortuneSessionEntity(
      sessionId: 'fs-1',
      teller: teller,
      durationMinutes: 10,
      totalJeton: 100,
      tellerUserId: 'user-teller',
      clientId: 'user-client',
      isClient: true,
    );

    test('client prefers room peerId', () {
      const room = LiveFortuneRoomInfo(
        sessionId: 'fs-1',
        status: 'active',
        maxMinutes: 10,
        timerStarted: false,
        peerId: 'user-teller-live',
        tellerUserId: 'user-teller-live',
      );
      expect(clientSession.remotePeerIdFor(room: room), 'user-teller-live');
    });

    test('teller prefers room peerId as client id', () {
      const tellerSession = LiveFortuneSessionEntity(
        sessionId: 'fs-1',
        teller: teller,
        durationMinutes: 10,
        totalJeton: 100,
        clientId: 'user-client',
        isClient: false,
      );
      const room = LiveFortuneRoomInfo(
        sessionId: 'fs-1',
        status: 'active',
        maxMinutes: 10,
        timerStarted: false,
        peerId: 'user-client',
        clientId: 'user-client',
        isTeller: true,
        isUser: false,
      );
      expect(tellerSession.remotePeerIdFor(room: room), 'user-client');
    });
  });
}
