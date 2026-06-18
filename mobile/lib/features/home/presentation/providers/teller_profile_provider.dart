import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import 'home_providers.dart';
import '../../../shell/presentation/providers/role_panel_providers.dart';

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

  bool get isApprovedTeller => profile?.isUsable == true;

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
    return ApprovedTellerState(loading: user != null);
  }

  Future<void> refresh() async {
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      state = const ApprovedTellerState(checked: true);
      return;
    }
    state = state.copyWith(loading: true);
    final profile = await ref.read(rolePanelResolverProvider).resolveTeller(user);
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
