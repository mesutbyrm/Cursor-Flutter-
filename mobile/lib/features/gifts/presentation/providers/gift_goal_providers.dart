import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/gift_goal_remote_datasource.dart';
import '../../domain/gift_goal.dart';

final giftGoalRemoteProvider = Provider<GiftGoalRemoteDataSource>((ref) {
  return GiftGoalRemoteDataSource(ref.watch(dioProvider));
});

/// (context, contextId) anahtarı.
typedef GiftGoalKey = ({String context, String contextId});

/// Bir hedefin canlı durumu + tamamlanma sinyali.
class GiftGoalState {
  const GiftGoalState({this.goal, this.justCompleted = false});

  final GiftGoal? goal;

  /// Bu tick'te hedef ilk kez doldu — kutlama tetiklenmeli.
  final bool justCompleted;

  GiftGoalState copyWith({GiftGoal? goal, bool? justCompleted}) => GiftGoalState(
        goal: goal ?? this.goal,
        justCompleted: justCompleted ?? this.justCompleted,
      );
}

/// Bir bağlamdaki aktif hediye hedefini canlı takip eder (poll).
class GiftGoalController
    extends AutoDisposeFamilyNotifier<GiftGoalState, GiftGoalKey> {
  Timer? _timer;
  bool _wasCompleted = false;

  @override
  GiftGoalState build(GiftGoalKey arg) {
    ref.onDispose(() => _timer?.cancel());
    _start();
    return const GiftGoalState();
  }

  void _start() {
    _timer?.cancel();
    unawaited(_tick());
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _tick());
  }

  Future<void> _tick() async {
    try {
      final remote = ref.read(giftGoalRemoteProvider);
      final goals = await remote.fetchGoals(
        context: arg.context,
        contextId: arg.contextId,
      );
      // Aktif hedefi (yoksa en son hedefi) seç.
      GiftGoal? goal;
      for (final g in goals) {
        if (g.isActive) {
          goal = g;
          break;
        }
      }
      goal ??= goals.isNotEmpty ? goals.first : null;

      final completedNow = goal?.isCompleted ?? false;
      final justCompleted = completedNow && !_wasCompleted;
      _wasCompleted = completedNow;
      state = GiftGoalState(goal: goal, justCompleted: justCompleted);
    } catch (_) {
      // sessiz — bir sonraki tick'te tekrar denenir
    }
  }

  /// Kutlama gösterildikten sonra bayrağı düşür.
  void acknowledgeCelebration() {
    if (state.justCompleted) {
      state = state.copyWith(justCompleted: false);
    }
  }

  /// Yeni hedef oluşturulduktan sonra anında takibe al.
  void adopt(GiftGoal goal) {
    _wasCompleted = goal.isCompleted;
    state = GiftGoalState(goal: goal);
    _start();
  }

  /// Manuel yenile.
  Future<void> refresh() => _tick();
}

final giftGoalProvider = AutoDisposeNotifierProviderFamily<GiftGoalController,
    GiftGoalState, GiftGoalKey>(GiftGoalController.new);
