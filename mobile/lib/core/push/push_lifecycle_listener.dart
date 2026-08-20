import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/router/app_router.dart';
import '../../features/admin/presentation/providers/admin_providers.dart';
import '../../features/admin/presentation/providers/staff_access_provider.dart';
import '../../features/auth/domain/entities/user_entity.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/live_psychics/presentation/controllers/psychic_flow.dart';
import '../../features/live_psychics/presentation/controllers/psychic_push_action_bridge.dart';
import '../../features/live_psychics/presentation/controllers/psychic_invite_coordinator.dart';
import '../../features/live_psychics/presentation/controllers/psychic_incoming_controller.dart';
import '../../features/live_psychics/presentation/providers/live_psychics_providers.dart';
import '../../features/live_psychics/presentation/providers/psychic_booking_feedback_provider.dart';
import '../../features/profile/presentation/providers/profile_providers.dart';
import '../../features/wallet/domain/wallet_balances.dart';
import '../../features/live_psychics/presentation/controllers/psychics_list_controller.dart';
import '../../features/live_psychics/presentation/diagnostics/psychic_invite_diagnostic_provider.dart';
import '../../features/live_psychics/presentation/providers/psychic_push_payload.dart';
import '../../features/live_psychics/presentation/providers/psychic_session_ended_provider.dart';
import '../../features/live_psychics/presentation/providers/psychic_session_cancel_signal.dart';
import '../../features/messages/presentation/providers/conversations_list_notifier.dart';
import '../../features/messages/presentation/providers/messages_providers.dart';
import '../../features/notifications/presentation/providers/notifications_list_notifier.dart';
import '../../features/notifications/presentation/providers/notifications_providers.dart';
import '../../features/voice_hub/presentation/utils/voice_room_session_utils.dart';
import '../onesignal/onesignal_bootstrap.dart';
import 'push_notification_service.dart';
import 'push_navigation_handler.dart';
import 'push_registrar.dart';

/// Oturum açıldığında push eşlemesi ve token kaydı.
/// İzin diyaloğu shell ilk frame'inden sonra gecikmeli açılır.
class PushLifecycleListener extends ConsumerStatefulWidget {
  const PushLifecycleListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushLifecycleListener> createState() =>
      _PushLifecycleListenerState();
}

class _PushLifecycleListenerState extends ConsumerState<PushLifecycleListener> {
  Timer? _pushSyncTimer;
  Timer? _adminPollTimer;
  bool _pushSyncing = false;
  int _lastPendingCount = -1;

  @override
  void initState() {
    super.initState();
    bindPushRegistrarTokenRefresh(() {
      if (!mounted) return;
      ref.read(pushRegistrarProvider).registerIfPossible(allowTokenRetry: true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      PushNavigationHandler.install(
        ref.read(goRouterProvider),
        onReceived: _onPushReceived,
        onFortuneInviteData: (data) {
          final invite = parsePsychicIncomingLoose(data);
          if (invite == null) return;
          final uid = ref.read(authControllerProvider).valueOrNull?.id;
          final approved = ref.read(approvedPsychicProvider);
          final decision = evaluatePsychicIncomingInvite(
            authUserId: uid,
            invite: invite,
            tellerProfileId: approved.profile?.id,
            isFortuneTeller:
                approved.profile != null && approved.profile!.isUsable,
          );
          ref.read(psychicInviteDiagnosticProvider.notifier).record(
                sessionId: invite.sessionId,
                decision: decision,
                source: 'push',
              );
          if (!decision.present) return;
          ref.read(psychicIncomingQueueProvider.notifier).enqueue(invite);
          PsychicInviteCoordinator.requestPresent(sessionId: invite.sessionId);
        },
        onSessionCancelledData: (cancelled) {
          ref
              .read(psychicSessionCancelSignalProvider.notifier)
              .signal(cancelled.sessionId);
          ref.read(psychicIncomingQueueProvider.notifier).remove(cancelled.sessionId);
          ref.read(psychicDismissedSessionsProvider.notifier).update(
                (s) => {...s, cancelled.sessionId},
              );
        },
        onSessionUpdateData: (update) {
          if (update.isAccepted) {
            unawaited(
              PsychicFlow.resumeFromPush(
                router: ref.read(goRouterProvider),
                sessionId: update.sessionId,
                tellerId: update.tellerId,
                repo: ref.read(livePsychicsRepositoryProvider),
              ),
            );
            return;
          }
          if (update.isRejected) {
            ref
                .read(psychicSessionCancelSignalProvider.notifier)
                .signal(update.sessionId);
            ref.read(psychicBookingFeedbackProvider.notifier).state =
                'Randevu reddedildi — jetonlar iade edildi';
            ref.refreshWalletCache(force: true);
          }
        },
        onSessionEndedData: (ended) {
          ref
              .read(psychicSessionCancelSignalProvider.notifier)
              .signal(ended.sessionId);
          ref.read(psychicSessionEndedProvider.notifier).state =
              PsychicSessionEndedEvent(
            sessionId: ended.sessionId,
            tellerId: ended.tellerId,
            tellerName: ended.tellerName,
            durationMinutes:
                ended.durationMinutes != null && ended.durationMinutes! > 0
                    ? ended.durationMinutes
                    : null,
            totalJeton:
                ended.totalJeton != null && ended.totalJeton! > 0
                    ? ended.totalJeton
                    : null,
            message: ended.message,
            promptReview: true,
            navigateAfter: true,
          );
          ref.refreshWalletCache(force: true);
        },
        onPrepareVoiceRoomSwitch: (nextLiveKey, {source = 'push'}) =>
            prepareVoiceRoomSwitch(
              ref,
              nextLiveKey: nextLiveKey,
              source: source,
            ),
      );
      PushNavigationHandler.staffCanManagePayments = () =>
          ref.read(staffAccessProvider).canManagePayments;
      PsychicPushActionBridge.onRespond = (
        String sessionId,
        String action,
        Map<String, dynamic> data,
      ) async {
        final repo = ref.read(livePsychicsRepositoryProvider);
        await repo.respondSession(sessionId, action: action);
        if (action == 'accept') {
          final tellerId = data['tellerId']?.toString() ??
              data['tellerUserId']?.toString();
          await PsychicFlow.resumeFromPush(
            router: ref.read(goRouterProvider),
            sessionId: sessionId,
            tellerId: tellerId,
            repo: repo,
          );
        } else {
          ref.read(psychicIncomingQueueProvider.notifier).remove(sessionId);
          ref.read(psychicSessionCancelSignalProvider.notifier).signal(sessionId);
        }
      };
      _queuePushSync(null, ref.read(authControllerProvider));
    });

    ref.listenManual<AsyncValue<UserEntity?>>(
      authControllerProvider,
      _queuePushSync,
    );

    _adminPollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _pollAdminPayments();
    });

    // Wallet yüklenir yüklenmez admin kontrolü yap.
    ref.listenManual<AsyncValue<WalletBalances>>(
      walletBalancesProvider,
      (prev, next) {
        if (!mounted) return;
        if (next.hasValue && !prev!.hasValue) {
          unawaited(_pollAdminPayments());
        }
      },
    );
  }

  Future<void> _pollAdminPayments() async {
    final access = ref.read(staffAccessProvider);
    if (!access.canManagePayments) return;
    try {
      ref.invalidate(adminPaymentRequestsProvider);
      final requests = await ref.read(adminPaymentRequestsProvider.future);
      final count = requests.length;
      if (_lastPendingCount >= 0 && count > _lastPendingCount) {
        final newCount = count - _lastPendingCount;
        if (!OneSignalBootstrap.isReady) {
          unawaited(
            PushNotificationService.instance.showLocal(
              id: 9001,
              title: 'Yeni Ödeme Talebi',
              body: '$newCount yeni ödeme talebi bekliyor',
              payload: '/admin',
              urgent: true,
            ),
          );
        }
      }
      _lastPendingCount = count;
    } catch (_) {}
  }

  void _queuePushSync(
    AsyncValue<UserEntity?>? previous,
    AsyncValue<UserEntity?> next,
  ) {
    _pushSyncTimer?.cancel();
    // Sistem izin diyaloğunu shell ilk frame'inden sonra açarak geçiş
    // bariyerleriyle çakışmasını önler.
    _pushSyncTimer = Timer(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      unawaited(_syncPushForAuth(previous, next));
    });
  }

  Future<void> _syncPushForAuth(
    AsyncValue<UserEntity?>? previous,
    AsyncValue<UserEntity?> next,
  ) async {
    if (_pushSyncing) return;
    _pushSyncing = true;
    try {
      final user = next.valueOrNull;
      if (user == null) {
        if (previous?.valueOrNull != null) {
          ref.read(pushRegistrarProvider).forgetLastRegistration();
          await OneSignalBootstrap.logout();
        }
        return;
      }

      await OneSignalBootstrap.login(user.id);
      if (OneSignalBootstrap.isReady) {
        if (!OneSignalBootstrap.permissionGranted) {
          await OneSignalBootstrap.requestPermission();
        }
      } else if (!PushNotificationService.instance.permissionGranted) {
        await PushNotificationService.instance.requestSystemPermission();
      }

      await ref
          .read(pushRegistrarProvider)
          .registerIfPossible(allowTokenRetry: true);
    } finally {
      _pushSyncing = false;
    }
  }

  void _onPushReceived() {
    if (!mounted) return;
    ref.invalidate(notificationsListProvider);
    ref.invalidate(notificationsListNotifierProvider);
    ref.invalidate(conversationsProvider);
    unawaited(
      ref.read(conversationsListNotifierProvider.notifier).refresh(
            silent: true,
            forceRefresh: true,
          ),
    );
    ref.invalidate(adminPaymentNotificationsProvider);
    ref.invalidate(adminPaymentRequestsProvider);
    // Push gelince admin bekleyen talep sayısını hemen kontrol et.
    unawaited(_pollAdminPayments());
  }

  @override
  void dispose() {
    _adminPollTimer?.cancel();
    _pushSyncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
