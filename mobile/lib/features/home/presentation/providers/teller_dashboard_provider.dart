import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/token_storage.dart';
import '../../data/services/live_fortune_teller_incoming_sse_service.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../widgets/fortune_incoming_invite_host.dart';
import 'fortune_incoming_invite_provider.dart';
import 'home_providers.dart';
import 'teller_profile_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class TellerDashboardState {
  const TellerDashboardState({
    this.profile,
    this.pendingSessions = const [],
    this.activeSessionCount = 0,
    this.activeSessionElapsedSec = 0,
    this.sessionEarningsJeton = 0,
    this.loading = true,
    this.togglingOnline = false,
    this.sseConnected = false,
    this.lastApiLog,
  });

  final LiveFortuneTellerEntity? profile;
  final List<FortuneIncomingSession> pendingSessions;
  final int activeSessionCount;
  final int activeSessionElapsedSec;
  final int sessionEarningsJeton;
  final bool loading;
  final bool togglingOnline;
  final bool sseConnected;
  final String? lastApiLog;

  int get pendingCount => pendingSessions.length;

  double? get pricePerMinute =>
      profile != null ? profile!.pricePerMinute.toDouble() : null;

  TellerDashboardState copyWith({
    LiveFortuneTellerEntity? profile,
    List<FortuneIncomingSession>? pendingSessions,
    int? activeSessionCount,
    int? activeSessionElapsedSec,
    int? sessionEarningsJeton,
    bool? loading,
    bool? togglingOnline,
    bool? sseConnected,
    String? lastApiLog,
  }) {
    return TellerDashboardState(
      profile: profile ?? this.profile,
      pendingSessions: pendingSessions ?? this.pendingSessions,
      activeSessionCount: activeSessionCount ?? this.activeSessionCount,
      activeSessionElapsedSec:
          activeSessionElapsedSec ?? this.activeSessionElapsedSec,
      sessionEarningsJeton: sessionEarningsJeton ?? this.sessionEarningsJeton,
      loading: loading ?? this.loading,
      togglingOnline: togglingOnline ?? this.togglingOnline,
      sseConnected: sseConnected ?? this.sseConnected,
      lastApiLog: lastApiLog ?? this.lastApiLog,
    );
  }
}

/// Falcı paneli — SSE + 3 sn yedek poll.
class TellerDashboardNotifier extends AutoDisposeNotifier<TellerDashboardState> {
  Timer? _poll;
  Timer? _sessionTimer;
  final Set<String> _handledSessions = {};

  @override
  TellerDashboardState build() {
    ref.onDispose(() {
      _poll?.cancel();
      _sessionTimer?.cancel();
      ref.read(liveFortuneTellerIncomingSseServiceProvider).disconnect();
    });
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
    await _connectSse();
    await _pollPending();
  }

  Future<void> _connectSse() async {
    final profile = state.profile ?? ref.read(approvedTellerProvider).profile;
    if (profile == null || !profile.isUsable) return;
    final tokens = ref.read(tokenStorageProvider);
    await ref.read(liveFortuneTellerIncomingSseServiceProvider).connect(
          accessToken: tokens.readAccess,
          onRequest: (session) {
            ref.read(fortuneIncomingInviteProvider.notifier).enqueue(session);
            unawaited(_pollPending());
          },
        );
    state = state.copyWith(sseConnected: true);
  }

  Future<void> refresh() async {
    await ref.read(approvedTellerProvider.notifier).refresh();
    state = state.copyWith(profile: ref.read(approvedTellerProvider).profile);
    await _connectSse();
    await _pollPending();
  }

  Future<void> _pollPending() async {
    final profile = state.profile ?? ref.read(approvedTellerProvider).profile;
    if (profile == null || !profile.isUsable) return;

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
      sessionEarningsJeton: _estimateEarnings(profile, activeForTeller),
      lastApiLog: pending.isEmpty
          ? 'GET /api/fortune-tellers/sessions?status=pending → boş'
          : 'GET /api/fortune-tellers/sessions?status=pending → ${pending.length} kayıt',
    );

    _syncSessionTimer(activeForTeller > 0);

    if (pending.isNotEmpty) {
      for (final session in pending) {
        if (_handledSessions.contains(session.sessionId)) continue;
        ref.read(fortuneIncomingInviteProvider.notifier).enqueue(session);
      }
    }
  }

  void markHandled(String sessionId) {
    _handledSessions.add(sessionId);
  }

  int _estimateEarnings(LiveFortuneTellerEntity profile, int activeSessions) {
    if (activeSessions <= 0) return 0;
    final ppm = profile.pricePerMinute;
    if (ppm <= 0) return 0;
    final minutes = state.activeSessionElapsedSec ~/ 60;
    return (minutes * ppm).round();
  }

  void _syncSessionTimer(bool active) {
    if (!active) {
      _sessionTimer?.cancel();
      _sessionTimer = null;
      if (state.activeSessionElapsedSec != 0) {
        state = state.copyWith(activeSessionElapsedSec: 0, sessionEarningsJeton: 0);
      }
      return;
    }
    _sessionTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      final profile = state.profile;
      if (profile == null) return;
      final next = state.activeSessionElapsedSec + 1;
      state = state.copyWith(
        activeSessionElapsedSec: next,
        sessionEarningsJeton: _estimateEarnings(profile, state.activeSessionCount),
      );
    });
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
