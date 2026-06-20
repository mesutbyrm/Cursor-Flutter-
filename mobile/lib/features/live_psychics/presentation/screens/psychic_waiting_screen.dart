import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/core/network/token_storage.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/ui/premium/live_badge.dart';
import 'package:canlifal_social/core/ui/premium_2026/cosmic_galaxy_background.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_booking_feedback_provider.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_close_dialog.dart';
import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_room_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';
import 'package:canlifal_social/features/live_psychics/domain/repositories/live_psychics_repository.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_session_cancel_signal.dart';
import 'package:canlifal_social/features/profile/presentation/providers/profile_providers.dart';

enum PsychicWaitingPhase {
  waiting,
  accepted,
  rejected,
  expired,
}

/// PDF: falcı yanıt vermezse 2–3 dk sonra bekleme sona erer.
const psychicWaitingTimeoutSeconds = 180;

class PsychicWaitingState {
  const PsychicWaitingState({
    this.phase = PsychicWaitingPhase.waiting,
    this.cancelling = false,
    this.closed = false,
    this.remainingSeconds = psychicWaitingTimeoutSeconds,
  });

  final PsychicWaitingPhase phase;
  final bool cancelling;
  final bool closed;
  final int remainingSeconds;

  String get statusLabel => switch (phase) {
        PsychicWaitingPhase.waiting => 'Bekliyor',
        PsychicWaitingPhase.accepted => 'Kabul',
        PsychicWaitingPhase.rejected => 'Red',
        PsychicWaitingPhase.expired => 'Süre doldu',
      };

  String get remainingLabel {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  PsychicWaitingState copyWith({
    PsychicWaitingPhase? phase,
    bool? cancelling,
    bool? closed,
    int? remainingSeconds,
  }) {
    return PsychicWaitingState(
      phase: phase ?? this.phase,
      cancelling: cancelling ?? this.cancelling,
      closed: closed ?? this.closed,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}

class PsychicWaitingController extends StateNotifier<PsychicWaitingState> {
  PsychicWaitingController(this.ref, this.session)
      : super(const PsychicWaitingState()) {
    _init();
  }

  final Ref ref;
  final PsychicSessionEntity session;
  Timer? _poll;
  Timer? _timeout;
  var _navigated = false;

  Future<void> _init() async {
    await PsychicSessionStore.save(session);
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _checkStatus());
    _timeout = Timer.periodic(const Duration(seconds: 1), (_) => _tickTimeout());
    unawaited(_checkStatus());
    unawaited(_connectSse());
  }

  void onRemoteCancelled() {
    if (!state.closed) unawaited(_onRejected());
  }

  void _tickTimeout() {
    if (state.closed || state.phase != PsychicWaitingPhase.waiting) return;
    final next = state.remainingSeconds - 1;
    if (next <= 0) {
      _timeout?.cancel();
      unawaited(_onExpired());
      return;
    }
    state = state.copyWith(remainingSeconds: next);
  }

  Future<void> _connectSse() async {
    final storage = ref.read(tokenStorageProvider);
    await ref.read(psychicRoomSseServiceProvider).connect(
          sessionId: session.sessionId,
          accessToken: storage.readAccess,
          onRoomUpdate: (room) {
            if (state.closed) return;
            _handleRoomStatus(room.status);
          },
          onSessionEnded: (_) {
            if (state.closed) return;
            unawaited(_onRejected());
          },
        );
  }

  void _handleRoomStatus(PsychicSessionStatus status) {
    if (status == PsychicSessionStatus.rejected ||
        status == PsychicSessionStatus.cancelled) {
      unawaited(_onRejected());
      return;
    }
    if (status == PsychicSessionStatus.expired) {
      unawaited(_onExpired());
      return;
    }
    if (status.isActive) {
      unawaited(_onAccepted());
    }
  }

  Future<void> _checkStatus() async {
    if (state.closed) return;
    final status = await ref
        .read(livePsychicsRepositoryProvider)
        .fetchSessionStatus(session.sessionId);
    if (status == null) return;

    if (status.status == PsychicSessionStatus.rejected ||
        status.status == PsychicSessionStatus.cancelled) {
      await _onRejected();
      return;
    }
    if (status.status == PsychicSessionStatus.expired) {
      await _onExpired();
      return;
    }
    if (status.status.isActive) {
      await _onAccepted(status);
    }
  }

  Future<void> _onAccepted([PsychicSessionStatusResult? status]) async {
    if (state.closed || _navigated) return;
    _navigated = true;
    state = state.copyWith(phase: PsychicWaitingPhase.accepted, closed: true);
    _poll?.cancel();
    _timeout?.cancel();
    final activeSession = session.copyWith(
      tellerUserId: status?.tellerUserId ?? session.tellerUserId,
      trtcRoomIdOverride: status?.trtcRoomId,
      durationMinutes: status?.durationMinutes ?? session.durationMinutes,
      totalJeton: status?.totalJeton ?? session.totalJeton,
    );
    await PsychicSessionStore.save(activeSession);
    await ref.read(psychicRoomSseServiceProvider).disconnect();
    ref.read(psychicWaitingNavProvider.notifier).state = activeSession;
  }

  Future<void> _onRejected() async {
    if (state.closed) return;
    state = state.copyWith(phase: PsychicWaitingPhase.rejected, closed: true);
    _poll?.cancel();
    _timeout?.cancel();
    await ref.read(psychicRoomSseServiceProvider).disconnect();
    await PsychicSessionStore.clear();
    ref.invalidate(coinBalanceProvider);
    ref.read(psychicBookingFeedbackProvider.notifier).state =
        'Falcı randevunuzu reddetti';
    ref.read(psychicWaitingExitProvider.notifier).state = session.psychic.id;
  }

  void acknowledgeExit() {
    if (!state.closed) return;
    ref.read(psychicWaitingExitProvider.notifier).state = session.psychic.id;
  }

  Future<void> _onExpired() async {
    if (state.closed) return;
    state = state.copyWith(phase: PsychicWaitingPhase.expired, closed: true);
    _poll?.cancel();
    _timeout?.cancel();
    unawaited(
      ref.read(livePsychicsRepositoryProvider).endSession(session.sessionId),
    );
    await ref.read(psychicRoomSseServiceProvider).disconnect();
    await PsychicSessionStore.clear();
    ref.invalidate(coinBalanceProvider);
    ref.read(psychicBookingFeedbackProvider.notifier).state =
        'Falcı yanıt vermedi — süre doldu, jetonlar iade edildi';
    ref.read(psychicWaitingExitProvider.notifier).state = session.psychic.id;
  }

  Future<void> cancel(BuildContext context) async {
    if (state.closed) return;

    final confirmed = await showPsychicCloseDialog(
      context,
      title: 'Randevuyu iptal et?',
      message:
          '${session.psychic.name} ile randevunuzu iptal etmek istediğinize emin misiniz?',
      confirmLabel: 'İptal Et',
    );
    if (!confirmed) return;

    ref
        .read(psychicSessionCancelSignalProvider.notifier)
        .signal(session.sessionId);
    await _exitImmediate();
    unawaited(
      ref.read(livePsychicsRepositoryProvider).endSession(session.sessionId),
    );
  }

  Future<void> _exitImmediate() async {
    if (state.closed) return;
    state = state.copyWith(closed: true);
    _poll?.cancel();
    _timeout?.cancel();
    await ref.read(psychicRoomSseServiceProvider).disconnect();
    await PsychicSessionStore.clear();
    ref.invalidate(coinBalanceProvider);
    ref.read(psychicWaitingExitProvider.notifier).state = session.psychic.id;
  }

  @override
  void dispose() {
    _poll?.cancel();
    _timeout?.cancel();
    unawaited(ref.read(psychicRoomSseServiceProvider).disconnect());
    super.dispose();
  }
}

final psychicWaitingControllerProvider = StateNotifierProvider.autoDispose
    .family<PsychicWaitingController, PsychicWaitingState, PsychicSessionEntity>(
  (ref, session) => PsychicWaitingController(ref, session),
);

final psychicWaitingNavProvider =
    StateProvider.autoDispose<PsychicSessionEntity?>((ref) => null);

final psychicWaitingExitProvider = StateProvider.autoDispose<String?>((ref) => null);

/// Danışan bekleme ekranı — falcı onayı.
class PsychicWaitingScreen extends ConsumerWidget {
  const PsychicWaitingScreen({super.key, required this.session});

  final PsychicSessionEntity session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waiting = ref.watch(psychicWaitingControllerProvider(session));
    final psychic = session.psychic;

    ref.listen<PsychicSessionEntity?>(psychicWaitingNavProvider, (prev, next) {
      if (next == null) return;
      context.pushReplacement(
        '/canli-falcilar/${next.psychic.id}/ad-transition',
        extra: next,
      );
      ref.read(psychicWaitingNavProvider.notifier).state = null;
    });

    ref.listen<String?>(psychicWaitingExitProvider, (prev, next) {
      if (next == null) return;
      context.go('/canli-falcilar/$next');
      ref.read(psychicWaitingExitProvider.notifier).state = null;
    });

    ref.listen<String?>(psychicSessionCancelSignalProvider, (prev, sessionId) {
      if (sessionId == session.sessionId) {
        ref
            .read(psychicWaitingControllerProvider(session).notifier)
            .onRemoteCancelled();
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await ref
            .read(psychicWaitingControllerProvider(session).notifier)
            .cancel(context);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0618),
        body: CosmicGalaxyBackground(
          child: Stack(
            children: [
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    const SizedBox(height: 36),
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  AppThemeColors.accentPink,
                                  AppThemeColors.accentPurple,
                                ],
                              ),
                            ),
                            child: psychic.avatarUrl != null &&
                                    psychic.avatarUrl!.isNotEmpty
                                ? CircleAvatar(
                                    radius: 52,
                                    backgroundImage: CachedNetworkImageProvider(
                                      psychic.avatarUrl!,
                                    ),
                                  )
                                : const UserAvatar(radius: 52),
                          ),
                          if (psychic.isOnline)
                            const Positioned(
                              right: 6,
                              bottom: 6,
                              child: LiveBadge(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      psychic.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withValues(alpha: 0.35),
                        border: Border.all(
                          color: AppThemeColors.accentPurple
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.hourglass_top_rounded,
                            color: AppThemeColors.accentCyan,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            waiting.phase == PsychicWaitingPhase.waiting
                                ? 'Lütfen Bekleyiniz...'
                                : waiting.statusLabel,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            switch (waiting.phase) {
                              PsychicWaitingPhase.waiting =>
                                '${psychic.name} randevunuzu onayladığında otomatik olarak odaya bağlanacaksınız.',
                              PsychicWaitingPhase.expired =>
                                'Falcı belirlenen sürede yanıt vermedi. Jetonlarınız iade edilir.',
                              PsychicWaitingPhase.rejected =>
                                'Falcı randevunuzu kabul etmedi. Jetonlarınız iade edilir.',
                              PsychicWaitingPhase.accepted =>
                                'Falcı kabul etti, odaya bağlanılıyor…',
                            },
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (waiting.phase == PsychicWaitingPhase.waiting) ...[
                            Text(
                              'Kalan süre: ${waiting.remainingLabel}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppThemeColors.accentCyan,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            'Durum: ${waiting.statusLabel}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.55),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (waiting.phase == PsychicWaitingPhase.expired ||
                              waiting.phase == PsychicWaitingPhase.rejected)
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () => ref
                                    .read(
                                      psychicWaitingControllerProvider(session)
                                          .notifier,
                                    )
                                    .acknowledgeExit(),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppThemeColors.accentPurple,
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Tamam',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: waiting.closed
                                    ? null
                                    : () => ref
                                        .read(
                                          psychicWaitingControllerProvider(
                                            session,
                                          ).notifier,
                                        )
                                        .cancel(context),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935),
                                  minimumSize: const Size.fromHeight(48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(Icons.close_rounded, size: 18),
                                label: const Text(
                                  'İptal Et',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, top: 8),
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      onPressed: () => ref
                          .read(psychicWaitingControllerProvider(session).notifier)
                          .cancel(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
