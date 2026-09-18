import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:canlifal_social/features/pk/data/pk_models.dart';
import 'package:canlifal_social/features/pk/data/pk_service.dart';
import 'package:canlifal_social/features/pk/presentation/providers/pk_providers.dart';
import 'package:canlifal_social/features/pk/presentation/providers/pk_session_notifier.dart';
import 'package:canlifal_social/features/voice_hub/domain/pk/pk_battle_remote_models.dart';
import 'package:canlifal_social/features/voice_hub/presentation/providers/pk_battle_remote_provider.dart';

/// `pkSessionProvider` autoDispose'dur: izleyici kalmadığında state imha olur
/// ve sonraki okuma boş bir PkSessionState döner. Navigasyon ya da sheet
/// açılışı izleyicileri bir kare için düşürdüğünde PK ekranı bu yüzden
/// sıfırlanıyordu. Süren maçta `keepAlive` ile korunuyor; maç bitince link
/// bırakılıyor (aksi halde sızıntı olur).
void main() {
  PkSessionArgs args() =>
      const PkSessionArgs(contextId: 'room-1', kind: PkContextKind.voice);

  ProviderContainer makeContainer(_FakePkService api) {
    final container = ProviderContainer(
      overrides: [
        pkServiceProvider.overrideWithValue(api),
        // Gerçek controller ağa çıkıyor; burada yalnızca yutucu gerekiyor.
        pkBattleRemoteProvider.overrideWith(_StubRemoteController.new),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// `build()` içindeki `Future.microtask(loadState)` ve ardındaki await'in
  /// tamamlanması için birkaç tur döndürür.
  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('süren maçta izleyici düşse de state korunur', () async {
    final api = _FakePkService(
      const PkBattle(id: 'pk-1', status: PkStatus.active),
    );
    final container = makeContainer(api);

    final sub = container.listen(pkSessionProvider(args()), (_, _) {});
    await settle();

    expect(container.read(pkSessionProvider(args())).battle?.id, 'pk-1');
    expect(api.getStateCalls, 1);

    // Tüm izleyiciler düşüyor — bug buradaydı.
    sub.close();
    await settle();

    expect(
      container.read(pkSessionProvider(args())).battle?.id,
      'pk-1',
      reason: 'süren maçta state korunmalı',
    );
    expect(
      api.getStateCalls,
      1,
      reason: 'provider imha edilip yeniden kurulmamalı',
    );
  });

  test('maç bitince link bırakılır ve provider imha olur', () async {
    final api = _FakePkService(
      const PkBattle(id: 'pk-2', status: PkStatus.completed),
    );
    final container = makeContainer(api);

    final sub = container.listen(pkSessionProvider(args()), (_, _) {});
    await settle();
    expect(api.getStateCalls, 1);

    sub.close();
    await settle();

    // Yeniden okuma provider'ı sıfırdan kurar: link bırakılmış demektir.
    container.read(pkSessionProvider(args()));
    await settle();

    expect(
      api.getStateCalls,
      2,
      reason: 'bitmiş maçta keepAlive tutulmamalı, aksi halde sızıntı olur',
    );
  });

  test('battle yoksa provider canlı tutulmaz', () async {
    final api = _FakePkService(null);
    final container = makeContainer(api);

    final sub = container.listen(pkSessionProvider(args()), (_, _) {});
    await settle();
    expect(api.getStateCalls, 1);

    sub.close();
    await settle();

    container.read(pkSessionProvider(args()));
    await settle();

    expect(api.getStateCalls, 2, reason: 'battle yokken tutulmamalı');
  });
}

class _FakePkService extends PkService {
  _FakePkService(this._battle) : super(Dio());

  final PkBattle? _battle;
  int getStateCalls = 0;

  @override
  Future<PkBattle?> getState(String contextId) async {
    getStateCalls += 1;
    return _battle;
  }
}

class _StubRemoteController extends PkBattleRemoteController {
  @override
  PkBattleRemote? build() => null;

  @override
  void ingestSseBattle(PkBattleRemote battle) {}

  @override
  void clear() {}
}
