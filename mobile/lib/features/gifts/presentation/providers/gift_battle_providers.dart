import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/gift_battle_remote_datasource.dart';
import '../../domain/gift_battle.dart';

final giftBattleRemoteProvider = Provider<GiftBattleRemoteDataSource>((ref) {
  return GiftBattleRemoteDataSource(ref.watch(dioProvider));
});

/// (context, contextId) anahtarı.
typedef GiftBattleKey = ({String context, String contextId});

/// Bir odadaki/yayındaki aktif hediye savaşını canlı takip eder (poll).
class GiftBattleController
    extends AutoDisposeFamilyNotifier<GiftBattle?, GiftBattleKey> {
  Timer? _timer;

  @override
  GiftBattle? build(GiftBattleKey arg) {
    ref.onDispose(() => _timer?.cancel());
    _start();
    return null;
  }

  void _start() {
    _timer?.cancel();
    unawaited(_tick());
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _tick());
  }

  Future<void> _tick() async {
    try {
      final remote = ref.read(giftBattleRemoteProvider);
      final current = state;
      GiftBattle? next;
      if (current != null && current.id.isNotEmpty && current.isActive) {
        next = await remote.getBattle(current.id);
      } else {
        next = await remote.activeBattle(
          context: arg.context,
          contextId: arg.contextId,
        );
      }
      // Bittiğinde bir tur daha göster (kazanan banner'ı için), sonra temizle.
      if (next != null && next.isEnded && current != null && current.isActive) {
        state = next; // kazanan gösterimi
        _timer?.cancel();
        _timer = Timer(const Duration(seconds: 6), () {
          state = null;
          _start();
        });
        return;
      }
      state = next;
    } catch (_) {
      // sessiz — bir sonraki tick'te tekrar denenir
    }
  }

  /// Savaş başlatıldıktan sonra anında takibe al.
  void adopt(GiftBattle battle) {
    state = battle;
    _start();
  }
}

final giftBattleProvider = AutoDisposeNotifierProviderFamily<GiftBattleController,
    GiftBattle?, GiftBattleKey>(GiftBattleController.new);
