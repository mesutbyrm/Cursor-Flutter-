import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../data/gift_goal_dismiss_storage.dart';
import '../../data/gift_goal_remote_datasource.dart';
import '../../domain/gift_goal.dart';

final giftGoalRemoteProvider = Provider<GiftGoalRemoteDataSource>((ref) {
  return GiftGoalRemoteDataSource(ref.watch(dioProvider));
});

/// (context, contextId) anahtarı.
typedef GiftGoalKey = ({String context, String contextId});

/// Bir hedefin canlı durumu + tamamlanma / süre dolumu sinyali.
class GiftGoalState {
  const GiftGoalState({
    this.goal,
    this.justCompleted = false,
    this.justExpired = false,
    this.dismissed = false,
  });

  final GiftGoal? goal;

  /// Bu tick'te hedef ilk kez doldu — kutlama tetiklenmeli.
  final bool justCompleted;

  /// Süre doldu, hedef tamamlanmadı.
  final bool justExpired;

  /// Kullanıcı tamamlanan hedef şeridini kapattı.
  final bool dismissed;

  GiftGoalState copyWith({
    GiftGoal? goal,
    bool? justCompleted,
    bool? justExpired,
    bool? dismissed,
  }) =>
      GiftGoalState(
        goal: goal ?? this.goal,
        justCompleted: justCompleted ?? this.justCompleted,
        justExpired: justExpired ?? this.justExpired,
        dismissed: dismissed ?? this.dismissed,
      );
}

/// Bir bağlamdaki aktif hediye hedefini canlı takip eder (poll).
class GiftGoalController
    extends AutoDisposeFamilyNotifier<GiftGoalState, GiftGoalKey> {
  Timer? _timer;
  bool _wasCompleted = false;
  Set<String> _dismissedGoalIds = {};

  @override
  GiftGoalState build(GiftGoalKey arg) {
    ref.onDispose(() => _timer?.cancel());
    unawaited(_loadDismissed());
    _start();
    return const GiftGoalState();
  }

  Future<void> _loadDismissed() async {
    _dismissedGoalIds = await GiftGoalDismissStorage.readDismissedIds(
      context: arg.context,
      contextId: arg.contextId,
    );
    if (state.goal != null &&
        _dismissedGoalIds.contains(state.goal!.id)) {
      state = state.copyWith(dismissed: true);
    }
  }

  void _start() {
    _timer?.cancel();
    unawaited(_tick());
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _tick());
  }

  Future<void> _tick() async {
    if (state.dismissed) return;
    if (_dismissedGoalIds.isEmpty) {
      _dismissedGoalIds = await GiftGoalDismissStorage.readDismissedIds(
        context: arg.context,
        contextId: arg.contextId,
      );
    }
    try {
      final remote = ref.read(giftGoalRemoteProvider);
      final goals = await remote.fetchGoals(
        context: arg.context,
        contextId: arg.contextId,
      );
      GiftGoal? goal;
      for (final g in goals) {
        if (g.isActive) {
          goal = g;
          break;
        }
      }
      goal ??= goals.isNotEmpty ? goals.first : null;
      goal = goal?.withResolvedDeadline();

      if (goal != null &&
          (goal.isCompleted ||
              goal.currentAmount >= goal.targetAmount ||
              goal.status.toLowerCase() == 'completed')) {
        if (_dismissedGoalIds.contains(goal.id)) {
          state = const GiftGoalState(dismissed: true);
          _timer?.cancel();
          return;
        }
        final justCompleted = !_wasCompleted;
        _wasCompleted = true;
        state = GiftGoalState(goal: goal, justCompleted: justCompleted);
        return;
      }

      if (goal != null && _dismissedGoalIds.contains(goal.id)) {
        state = state.copyWith(dismissed: true, goal: goal);
        return;
      }

      if (goal != null && goal.endsAt != null) {
        final expired = DateTime.now().isAfter(goal.endsAt!);
        if (expired && !goal.isCompleted) {
          final wasActive = state.goal?.id == goal.id && !state.justExpired;
          state = GiftGoalState(
            goal: goal,
            justExpired: wasActive,
            dismissed: true,
          );
          _timer?.cancel();
          unawaited(remote.closeGoal(goal.id));
          return;
        }
      }

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

  /// Kutlama bitti — prefs’e kaydet ve şeridi kaldır.
  Future<void> dismissAfterCelebration() async {
    final goal = state.goal;
    if (goal == null) return;
    await GiftGoalDismissStorage.dismiss(
      context: arg.context,
      contextId: arg.contextId,
      goalId: goal.id,
    );
    _dismissedGoalIds.add(goal.id);
    state = const GiftGoalState(dismissed: true);
    _timer?.cancel();
    try {
      await ref.read(giftGoalRemoteProvider).closeGoal(goal.id);
    } catch (_) {}
  }

  /// Kullanıcı X ile kapattı — aynı goalId tekrar gösterilmez.
  Future<void> dismissByUser() async {
    final goal = state.goal;
    if (goal == null) return;
    await GiftGoalDismissStorage.dismiss(
      context: arg.context,
      contextId: arg.contextId,
      goalId: goal.id,
    );
    _dismissedGoalIds.add(goal.id);
    state = state.copyWith(dismissed: true, justCompleted: false);
    _timer?.cancel();
    if (goal.isCompleted) {
      try {
        await ref.read(giftGoalRemoteProvider).closeGoal(goal.id);
      } catch (_) {}
    }
  }

  @Deprecated('Use dismissByUser')
  Future<void> dismissCompleted() => dismissByUser();

  /// Yeni hedef oluşturulduktan sonra anında takibe al.
  void adopt(GiftGoal goal, {int? fallbackDurationMinutes}) {
    final resolved = goal.withResolvedDeadline(
      fallbackDurationMinutes: fallbackDurationMinutes,
    );
    _wasCompleted = resolved.isCompleted;
    _dismissedGoalIds.remove(resolved.id);
    state = GiftGoalState(goal: resolved, dismissed: false);
    _start();
  }

  /// Manuel yenile.
  Future<void> refresh() => _tick();
}

final giftGoalProvider = AutoDisposeNotifierProviderFamily<GiftGoalController,
    GiftGoalState, GiftGoalKey>(GiftGoalController.new);
