import 'package:canlifal_social/features/gifts/data/gift_battle_remote_datasource.dart';
import 'package:canlifal_social/features/gifts/domain/gift_battle.dart';
import 'package:canlifal_social/features/gifts/presentation/providers/gift_battle_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGiftBattleRemote extends GiftBattleRemoteDataSource {
  _FakeGiftBattleRemote() : super(Dio(BaseOptions(baseUrl: 'http://test')));

  @override
  Future<GiftBattle?> activeBattle({
    required String context,
    required String contextId,
  }) async =>
      null;

  @override
  Future<GiftBattle?> getBattle(String id) async => null;
}

void main() {
  test('giftBattleProvider build does not read state before init', () async {
    final container = ProviderContainer(
      overrides: [
        giftBattleRemoteProvider.overrideWithValue(_FakeGiftBattleRemote()),
      ],
    );
    addTearDown(container.dispose);

    const key = (context: 'voice_room', contextId: 'room-abc');

    expect(() => container.read(giftBattleProvider(key)), returnsNormally);

    await Future<void>.delayed(Duration.zero);
    expect(container.read(giftBattleProvider(key)), isNull);
  });
}
