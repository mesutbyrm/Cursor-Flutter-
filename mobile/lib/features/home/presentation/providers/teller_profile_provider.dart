import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import 'home_providers.dart';

/// Giriş sonrası `GET /api/fortune-tellers/my-profile` — onaylı falcı bayrağı.
class ApprovedTellerState {
  const ApprovedTellerState({
    this.profile,
    this.loading = false,
    this.checked = false,
  });

  final LiveFortuneTellerEntity? profile;
  final bool loading;
  final bool checked;

  bool get isApprovedTeller => profile?.isApproved == true;

  ApprovedTellerState copyWith({
    LiveFortuneTellerEntity? profile,
    bool? loading,
    bool? checked,
    bool clearProfile = false,
  }) {
    return ApprovedTellerState(
      profile: clearProfile ? null : (profile ?? this.profile),
      loading: loading ?? this.loading,
      checked: checked ?? this.checked,
    );
  }
}

class ApprovedTellerNotifier extends Notifier<ApprovedTellerState> {
  @override
  ApprovedTellerState build() {
    ref.listen(authControllerProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user == null) {
        state = const ApprovedTellerState(checked: true);
        return;
      }
      if (prev?.valueOrNull?.id != user.id) {
        unawaited(refresh());
      }
    });
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user != null) {
      Future.microtask(refresh);
    }
    return const ApprovedTellerState(loading: user != null);
  }

  Future<void> refresh() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      state = const ApprovedTellerState(checked: true);
      return;
    }
    state = state.copyWith(loading: true);
    final repo = ref.read(liveFortuneRepositoryProvider);
    var profile = await repo.fetchMyProfile();
    if (profile == null) {
      final tellers = await repo.fetchTellers();
      for (final t in tellers) {
        if (t.userId == user.id || t.id == user.id) {
          profile = t;
          break;
        }
      }
    }
    state = ApprovedTellerState(
      profile: profile,
      loading: false,
      checked: true,
    );
  }
}

final approvedTellerProvider =
    NotifierProvider<ApprovedTellerNotifier, ApprovedTellerState>(
  ApprovedTellerNotifier.new,
);
