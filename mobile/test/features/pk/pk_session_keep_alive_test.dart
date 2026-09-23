import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/pk/data/pk_models.dart';
import 'package:canlifal_social/features/pk/data/pk_service.dart';
import 'package:canlifal_social/features/pk/presentation/providers/pk_providers.dart';
import 'package:canlifal_social/features/pk/presentation/providers/pk_session_notifier.dart';
import 'package:canlifal_social/features/voice_hub/data/datasources/pk_battle_remote_datasource.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/pk_battle_remote_provider.dart';
import 'package:canlifal_social/features/live/presentation/providers/live_providers.dart';

/// `pkSessionProvider` autoDispose'dur: izleyici kalmadığında state imha olur
/// ve sonraki okuma boş bir PkSessionState döner. Navigasyon ya da sheet
/// açılışı izleyicileri bir kare için düşürdüğünde PK ekranı bu yüzden
/// sıfırlanıyordu. Süren maçta `keepAlive` ile korunuyor; maç bitince link
/// bırakılıyor (aksi halde sızıntı olur).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PkSessionArgs args() =>
      const PkSessionArgs(contextId: 'room-1', kind: PkContextKind.voice);

  PkBattleRemote? remoteFrom(PkBattle? battle) {
    if (battle == null) return null;
    return PkBattleRemote(
      id: battle.id,
      battleType: 'voice_room',
      status: battle.status.name,
      challengerScore: battle.score1,
      opponentScore: battle.score2,
      secondsLeft: 120,
      durationSeconds: battle.duration,
      targetScore: 150000,
      voiceRoomId: battle.room1Id,
      opponentVoiceRoomId: battle.room2Id,
    );
  }

  ProviderContainer makeContainer(_FakePkRemoteDataSource remoteApi) {
    final container = ProviderContainer(
      overrides: [
        pkServiceProvider.overrideWithValue(_FakePkService(null)),
        pkBattleRemoteDataSourceProvider.overrideWithValue(remoteApi),
        pkBattleRemoteProvider.overrideWith(_StubRemoteController.new),
        voiceRoomByIdProvider.overrideWith((ref, id) async => null),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('süren maçta izleyici düşse de state korunur', () async {
    final remoteApi = _FakePkRemoteDataSource(
      remoteFrom(const PkBattle(id: 'pk-1', status: PkStatus.active)),
    );
    final container = makeContainer(remoteApi);

    final sub = container.listen(pkSessionProvider(args()), (_, _) {});
    await settle();

    expect(container.read(pkSessionProvider(args())).battle?.id, 'pk-1');
    expect(remoteApi.fetchRoomBattleCalls, 1);

    sub.close();
    await settle();

    expect(
      container.read(pkSessionProvider(args())).battle?.id,
      'pk-1',
      reason: 'süren maçta state korunmalı',
    );
    expect(
      remoteApi.fetchRoomBattleCalls,
      1,
      reason: 'provider imha edilip yeniden kurulmamalı',
    );
  });

  test('maç bitince link bırakılır ve provider imha olur', () async {
    final remoteApi = _FakePkRemoteDataSource(
      remoteFrom(const PkBattle(id: 'pk-2', status: PkStatus.completed)),
    );
    final container = makeContainer(remoteApi);

    final sub = container.listen(pkSessionProvider(args()), (_, _) {});
    await settle();
    expect(remoteApi.fetchRoomBattleCalls, 1);

    sub.close();
    await settle();

    container.read(pkSessionProvider(args()));
    await settle();

    expect(
      remoteApi.fetchRoomBattleCalls,
      2,
      reason: 'bitmiş maçta keepAlive tutulmamalı, aksi halde sızıntı olur',
    );
  });

  test('battle yoksa provider canlı tutulmaz', () async {
    final remoteApi = _FakePkRemoteDataSource(null);
    final container = makeContainer(remoteApi);

    final sub = container.listen(pkSessionProvider(args()), (_, _) {});
    await settle();
    expect(remoteApi.fetchRoomBattleCalls, 1);

    sub.close();
    await settle();

    container.read(pkSessionProvider(args()));
    await settle();

    expect(remoteApi.fetchRoomBattleCalls, 2, reason: 'battle yokken tutulmamalı');
  });
}

class _FakePkService extends PkService {
  _FakePkService(PkBattle? battle) : super(Dio());
}

class _FakePkRemoteDataSource extends PkBattleRemoteDataSource {
  _FakePkRemoteDataSource(this._battle) : super(Dio());

  final PkBattleRemote? _battle;
  int fetchRoomBattleCalls = 0;

  @override
  Future<PkBattleRemote?> fetchRoomBattle(
    String roomId, {
    String? alternateRoomId,
  }) async {
    fetchRoomBattleCalls += 1;
    return _battle;
  }

  @override
  Future<List<PkBattleRemote>> fetchMyInvites() async => const [];
}

class _StubRemoteController extends PkBattleRemoteController {
  @override
  PkBattleRemote? build() => null;

  @override
  void ingestSseBattle(PkBattleRemote battle) {}

  @override
  void clear() {}
}
