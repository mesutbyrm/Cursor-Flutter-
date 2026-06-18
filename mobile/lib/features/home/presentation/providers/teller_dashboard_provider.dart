import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/live_fortune_session_entity.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import 'home_providers.dart';
import 'teller_profile_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class TellerDashboardState {
  const TellerDashboardState({
    this.profile,
    this.pendingSessions = const [],
    this.activeSessionCount = 0,
    this.loading = true,
    this.togglingOnline = false,
    this.lastApiLog,
    this.popupSessionId,
  });

  final LiveFortuneTellerEntity? profile;
  final List<FortuneIncomingSession> pendingSessions;
  final int activeSessionCount;
  final bool loading;
  final bool togglingOnline;
  final String? lastApiLog;
  final String? popupSessionId;

  int get pendingCount => pendingSessions.length;

  TellerDashboardState copyWith({
    LiveFortuneTellerEntity? profile,
    List<FortuneIncomingSession>? pendingSessions,
    int? activeSessionCount,
    bool? loading,
    bool? togglingOnline,
    String? lastApiLog,
    String? popupSessionId,
    bool clearPopup = false,
  }) {
    return TellerDashboardState(
      profile: profile ?? this.profile,
      pendingSessions: pendingSessions ?? this.pendingSessions,
      activeSessionCount: activeSessionCount ?? this.activeSessionCount,
      loading: loading ?? this.loading,
      togglingOnline: togglingOnline ?? this.togglingOnline,
      lastApiLog: lastApiLog ?? this.lastApiLog,
      popupSessionId:
          clearPopup ? null : (popupSessionId ?? this.popupSessionId),
    );
  }
}

/// Falcı paneli — 3 sn pending poll (`GET .../sessions?status=pending`).
class TellerDashboardNotifier extends AutoDisposeNotifier<TellerDashboardState> {
  Timer? _poll;
  final Set<String> _handledSessions = {};

  @override
  TellerDashboardState build() {
    ref.onDispose(() => _poll?.cancel());
    Future.microtask(_bootstrap);
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _pollPending());
    return const TellerDashboardState();
  }

  Future<void> _bootstrap() async {
    final approved = ref.read(approvedTellerProvider);
    var profile = approved.profile;
    if (profile == null) {
      await ref.read(approvedTellerProvider.notifier).refresh();
      profile = ref.read(approvedTellerProvider).profile;
    }
    if (kDebugMode) {
      debugPrint('Teller dashboard loaded');
    }
    state = state.copyWith(profile: profile, loading: false);
    await _pollPending();
  }

  Future<void> refresh() async {
    await ref.read(approvedTellerProvider.notifier).refresh();
    state = state.copyWith(profile: ref.read(approvedTellerProvider).profile);
    await _pollPending();
  }

  Future<void> _pollPending() async {
    final profile = state.profile ?? ref.read(approvedTellerProvider).profile;
    if (profile == null || !profile.isApproved) return;

    final repo = ref.read(liveFortuneRepositoryProvider);
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    final incoming = await repo.fetchIncomingSessions(
      currentUserId: userId,
      tellerProfileId: profile.id,
    );
    final pendingOnly = await repo.fetchPendingSessions();
    final merged = <FortuneIncomingSession>[];
    final seen = <String>{};
    for (final row in [...incoming, ...pendingOnly]) {
      if (seen.add(row.sessionId)) merged.add(row);
    }
    final pending = merged;
    final active = await repo.fetchActiveSessions();
    final activeForTeller = active
        .where(
          (s) =>
              s.tellerProfileId == profile.id ||
              s.tellerUserId == profile.userId,
        )
        .length;

    if (kDebugMode) {
      debugPrint('Pending count: ${pending.length}');
      if (pending.isEmpty) {
        debugPrint(
          'Pending endpoint empty — see network log above for raw response',
        );
      }
    }

    state = state.copyWith(
      pendingSessions: pending,
      activeSessionCount: activeForTeller,
      lastApiLog: pending.isEmpty
          ? 'GET /api/fortune-tellers/sessions?status=pending → boş'
          : 'GET /api/fortune-tellers/sessions?status=pending → ${pending.length} kayıt',
    );

    if (pending.isNotEmpty) {
      final first = pending.first;
      if (!_handledSessions.contains(first.sessionId) &&
          state.popupSessionId != first.sessionId) {
        state = state.copyWith(popupSessionId: first.sessionId);
        if (kDebugMode) {
          debugPrint('Incoming popup opened');
        }
      }
    }
  }

  void clearPopup() {
    state = state.copyWith(clearPopup: true);
  }

  void markHandled(String sessionId) {
    _handledSessions.add(sessionId);
    if (state.popupSessionId == sessionId) {
      state = state.copyWith(clearPopup: true);
    }
  }

  Future<bool> toggleOnline() async {
    final profile = state.profile;
    if (profile == null) return false;
    state = state.copyWith(togglingOnline: true);
    final next = !profile.isOnline;
    final ok =
        await ref.read(liveFortuneRepositoryProvider).setOnline(online: next);
    if (ok) {
      state = state.copyWith(
        profile: LiveFortuneTellerEntity(
          id: profile.id,
          userId: profile.userId,
          name: profile.name,
          bio: profile.bio,
          avatarUrl: profile.avatarUrl,
          isOnline: next,
          rating: profile.rating,
          reviewCount: profile.reviewCount,
          pricePerMinute: profile.pricePerMinute,
          level: profile.level,
          specialties: profile.specialties,
          category: profile.category,
          applicationStatus: profile.applicationStatus,
          totalSessions: profile.totalSessions,
          totalEarnings: profile.totalEarnings,
        ),
        togglingOnline: false,
      );
    } else {
      state = state.copyWith(togglingOnline: false);
    }
    return ok;
  }

  Future<FortuneSessionRespondResult> acceptSession(
    FortuneIncomingSession session,
  ) async {
    final result =
        await ref.read(liveFortuneRepositoryProvider).respondSessionDetailed(
              session.sessionId,
              action: 'accept',
            );
    if (kDebugMode) {
      debugPrint('Accept response: ${result.raw}');
    }
    markHandled(session.sessionId);
    await _pollPending();
    return result;
  }

  Future<bool> rejectSession(FortuneIncomingSession session) async {
    final ok = await ref.read(liveFortuneRepositoryProvider).respondSession(
          session.sessionId,
          action: 'reject',
        );
    markHandled(session.sessionId);
    await _pollPending();
    return ok;
  }
}

final tellerDashboardProvider =
    AutoDisposeNotifierProvider<TellerDashboardNotifier, TellerDashboardState>(
  TellerDashboardNotifier.new,
);
