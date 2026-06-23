import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/app/router/app_router.dart';
import 'package:canlifal_social/core/bootstrap/auth_route_paths.dart';
import 'package:canlifal_social/core/network/token_storage.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live_psychics/data/services/psychic_incoming_sse_service.dart';
import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_request_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_flow.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_incoming_controller.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_invite_coordinator.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychics_list_controller.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_live_event_bus.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_push_payload.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_session_cancel_signal.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_incoming_call_dialog.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_status.dart';

/// Uygulama genelinde falcı gelen çağrı popup'ı — SSE + 2 sn poll + push.
class PsychicIncomingHost extends ConsumerStatefulWidget {
  const PsychicIncomingHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PsychicIncomingHost> createState() => _PsychicIncomingHostState();
}

class _PsychicIncomingHostState extends ConsumerState<PsychicIncomingHost>
    with WidgetsBindingObserver {
  Timer? _poll;
  Timer? _inviteStatusWatch;
  var _presenting = false;
  var _inviteUiReady = false;
  var _isFortuneTeller = false;
  String? _tellerProfileId;
  String? _activePresentingSessionId;
  PsychicIncomingSseService? _sseService;
  GoRouter? _router;
  String _routePath = '/feed';
  var _routeListenerAttached = false;

  bool _isSignedIn() {
    if (!_inviteUiReady) return false;
    final auth = ref.read(authControllerProvider);
    if (auth.isLoading) return false;
    return auth.valueOrNull != null;
  }

  bool _mayPresentInvites() {
    if (!_isSignedIn()) return false;
    final path = _router?.routerDelegate.currentConfiguration.uri.path ??
        ref.read(goRouterProvider).routerDelegate.currentConfiguration.uri.path;
    return _mayPresentInvitesForPath(path);
  }

  bool _mayRunTellerBackgroundSync() {
    if (!_isSignedIn()) return false;
    final path =
        ref.read(goRouterProvider).routerDelegate.currentConfiguration.uri.path;
    return !AuthRoutePaths.isPublicAuthPath(path);
  }

  bool _isInPsychicFlow(String path) {
    if (!path.contains('/canli-falcilar')) return false;
    return path.contains('/waiting') ||
        path.contains('/ad-transition') ||
        path.contains('/session');
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sseService = ref.read(psychicIncomingSseServiceProvider);
      _attachRouteListener(ref.read(goRouterProvider));
      setState(() => _inviteUiReady = true);
      PsychicInviteCoordinator.onRequestPresent = () {
        if (!mounted) return;
        if (!_inviteUiReady) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) unawaited(_tryPresentNext());
          });
          return;
        }
        unawaited(_tryPresentNext());
      };
      unawaited(_tryPresentNext());
      unawaited(_bootstrap());
    });
  }

  void _attachRouteListener(GoRouter router) {
    if (_routeListenerAttached && identical(_router, router)) return;
    _detachRouteListener();
    _router = router;
    _routePath = router.routerDelegate.currentConfiguration.uri.path;
    router.routerDelegate.addListener(_onRouteChanged);
    _routeListenerAttached = true;
  }

  void _detachRouteListener() {
    _router?.routerDelegate.removeListener(_onRouteChanged);
    _router = null;
    _routeListenerAttached = false;
  }

  void _onRouteChanged() {
    if (!mounted) return;
    final router = _router;
    if (router == null) return;
    final next = router.routerDelegate.currentConfiguration.uri.path;
    if (next == _routePath) return;
    final wasBlocked = !_mayPresentInvitesForPath(_routePath);
    _routePath = next;
    if (wasBlocked && _mayPresentInvites()) {
      unawaited(_tryPresentNext());
    }
  }

  bool _mayPresentInvitesForPath(String path) {
    if (!_isSignedIn()) return false;
    if (_isInPsychicFlow(path)) return false;
    return !AuthRoutePaths.isPublicAuthPath(path);
  }

  Future<void> _bootstrap() async {
    await _ensureTellerProfile();
    await _connectSse();
    _startPoll();
    if (_mayPresentInvites()) {
      unawaited(
        PsychicFlow.resumeActiveClientSessions(
          router: ref.read(goRouterProvider),
          repo: ref.read(livePsychicsRepositoryProvider),
        ),
      );
    }
  }

  void _startPoll() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _pollApi());
    unawaited(_pollApi());
  }

  Future<void> _ensureTellerProfile() async {
    if (!_mayRunTellerBackgroundSync()) return;

    var approved = ref.read(approvedPsychicProvider);
    if (!approved.checked || approved.profile == null) {
      await ref.read(approvedPsychicProvider.notifier).refresh();
      approved = ref.read(approvedPsychicProvider);
    }

    final profile = approved.profile;
    if (profile == null || !profile.isUsable) {
      _isFortuneTeller = false;
      _tellerProfileId = null;
      return;
    }

    final wasTeller = _isFortuneTeller;
    _isFortuneTeller = true;
    _tellerProfileId = profile.id;
    await ref.read(livePsychicsRepositoryProvider).setOnline(online: true);
    if (!wasTeller) {
      await _connectSse();
    }
  }

  Future<void> _connectSse() async {
    if (!_mayRunTellerBackgroundSync()) return;
    final PsychicIncomingSseService service =
        _sseService ?? ref.read(psychicIncomingSseServiceProvider);
    _sseService ??= service;
    final tokens = ref.read(tokenStorageProvider);
    await service.connect(
          accessToken: tokens.readAccess,
          onRequest: _onSseRequest,
        );
  }

  void _onSseRequest(PsychicRequestEntity req) {
    if (!mounted || !_mayRunTellerBackgroundSync()) return;
    if (!req.isPending) return;
    final uid = ref.read(authControllerProvider).valueOrNull?.id;
    if (!shouldPresentPsychicIncomingInvite(
      authUserId: uid,
      invite: req,
      tellerProfileId: _tellerProfileId,
      isFortuneTeller: _isFortuneTeller,
    )) {
      return;
    }
    ref.read(psychicIncomingQueueProvider.notifier).enqueue(req);
    PsychicInviteCoordinator.requestPresent(sessionId: req.sessionId);
    if (_mayPresentInvites()) {
      unawaited(_tryPresentNext());
    }
  }

  Future<void> _pollApi() async {
    if (!mounted || _presenting || !_mayRunTellerBackgroundSync()) return;

    if (_tellerProfileId == null) {
      await _ensureTellerProfile();
    }

    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    final incoming = await ref
        .read(livePsychicsRepositoryProvider)
        .fetchIncomingRequests(
          currentUserId: userId,
          tellerProfileId: _tellerProfileId,
        );
    if (!mounted) return;
    for (final req in incoming) {
      if (!req.isPending) continue;
      final uid = ref.read(authControllerProvider).valueOrNull?.id;
      if (!shouldPresentPsychicIncomingInvite(
        authUserId: uid,
        invite: req,
        tellerProfileId: _tellerProfileId,
        isFortuneTeller: _isFortuneTeller,
      )) {
        continue;
      }
      ref.read(psychicIncomingQueueProvider.notifier).enqueue(req);
      PsychicInviteCoordinator.requestPresent(sessionId: req.sessionId);
    }
    if (_mayPresentInvites()) {
      await _tryPresentNext();
    }
  }

  Future<void> _tryPresentNext() async {
    if (!mounted || _presenting || !_mayPresentInvites()) return;
    final dismissed = ref.read(psychicDismissedSessionsProvider);
    final next = ref.read(psychicIncomingQueueProvider.notifier).takeNext();
    if (next == null) return;
    if (dismissed.contains(next.sessionId)) {
      await _tryPresentNext();
      return;
    }
    if (PsychicInviteCoordinator.shouldDebounceShown(next.sessionId)) {
      await _tryPresentNext();
      return;
    }
    await _presentInvite(next);
  }

  void _dismissActiveInvite({bool addToDismissed = true}) {
    _inviteStatusWatch?.cancel();
    _inviteStatusWatch = null;
    final sessionId = _activePresentingSessionId;
    _activePresentingSessionId = null;
    if (sessionId != null && addToDismissed) {
      ref.read(psychicIncomingQueueProvider.notifier).remove(sessionId);
      ref.read(psychicDismissedSessionsProvider.notifier).update(
            (s) => {...s, sessionId},
          );
    }
    final navCtx = rootNavigatorKey.currentContext;
    if (navCtx != null && navCtx.mounted && _presenting) {
      Navigator.of(navCtx, rootNavigator: true).pop(null);
    }
  }

  void _watchInviteCancellation(PsychicRequestEntity req) {
    _inviteStatusWatch?.cancel();
    _activePresentingSessionId = req.sessionId;
    _inviteStatusWatch = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted || !_presenting) return;
      final status = await ref
          .read(livePsychicsRepositoryProvider)
          .fetchSessionStatus(req.sessionId);
      if (!mounted || !_presenting) return;
      final s = status?.status;
      if (s == PsychicSessionStatus.cancelled ||
          s == PsychicSessionStatus.rejected ||
          s == PsychicSessionStatus.expired ||
          s == PsychicSessionStatus.ended) {
        _dismissActiveInvite();
      }
    });
  }

  Future<void> _presentInvite(PsychicRequestEntity req) async {
    if (!mounted || !_mayPresentInvites()) {
      ref.read(psychicIncomingQueueProvider.notifier).enqueue(req);
      return;
    }
    _presenting = true;
    ref.read(psychicIncomingPresentingProvider.notifier).state = true;
    try {
      final navCtx = rootNavigatorKey.currentContext;
      if (navCtx == null || !navCtx.mounted) {
        ref.read(psychicIncomingQueueProvider.notifier).enqueue(req);
        return;
      }

      PsychicInviteCoordinator.markDialogShown(req.sessionId);
      _watchInviteCancellation(req);

      final accepted = await showPsychicIncomingCallDialog(
        navCtx,
        clientName: req.clientName,
        fortuneType: req.fortuneType,
        durationMinutes: req.durationMinutes,
        totalJeton: req.totalJeton,
        clientAvatarUrl: req.clientAvatarUrl,
      );
      if (!mounted) return;

      if (accepted == null) {
        ref.read(psychicIncomingQueueProvider.notifier).enqueue(req);
        return;
      }

      if (!accepted) {
        await ref
            .read(livePsychicsRepositoryProvider)
            .respondSession(req.sessionId, action: 'reject');
        ref.read(psychicDismissedSessionsProvider.notifier).update(
              (s) => {...s, req.sessionId},
            );
        return;
      }

      final respond = await ref
          .read(livePsychicsRepositoryProvider)
          .respondSession(req.sessionId, action: 'accept');
      if (!mounted) return;
      if (!respond.success) {
        if (navCtx.mounted) {
          ScaffoldMessenger.of(navCtx).showSnackBar(
            const SnackBar(
              content: Text('Kabul sunucuya iletilemedi. Tekrar deneyin.'),
            ),
          );
        }
        ref.read(psychicIncomingQueueProvider.notifier).enqueue(req);
        return;
      }

      final approved = ref.read(approvedPsychicProvider).profile;
      final user = ref.read(authControllerProvider).valueOrNull;
      final psychic = approved ??
          PsychicEntity(
            id: req.tellerId,
            userId: req.tellerUserId,
            name: user?.displayName ?? 'Falcı',
            isOnline: true,
          );

      final session = PsychicSessionEntity(
        sessionId: req.sessionId,
        psychic: psychic,
        durationMinutes: req.durationMinutes,
        totalJeton: req.totalJeton,
        tellerUserId: req.tellerUserId ?? psychic.trtcUserId,
        clientId: req.clientId,
        isClient: false,
        trtcRoomIdOverride: respond.roomId ?? req.sessionId,
        fortuneType: req.fortuneType,
      );
      await PsychicSessionStore.save(session);
      ref.read(psychicDismissedSessionsProvider.notifier).update(
            (s) => {...s, req.sessionId},
          );
      if (navCtx.mounted) {
        await navCtx.push(
          '/canli-falcilar/${psychic.id}/session',
          extra: session,
        );
      }
    } finally {
      _inviteStatusWatch?.cancel();
      _inviteStatusWatch = null;
      _activePresentingSessionId = null;
      _presenting = false;
      ref.read(psychicIncomingPresentingProvider.notifier).state = false;
      if (mounted) await _tryPresentNext();
    }
  }

  @override
  void dispose() {
    PsychicInviteCoordinator.onRequestPresent = null;
    WidgetsBinding.instance.removeObserver(this);
    _detachRouteListener();
    _poll?.cancel();
    _inviteStatusWatch?.cancel();
    unawaited(_sseService?.disconnect());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_bootstrap());
      unawaited(_tryPresentNext());
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);
    if (!identical(router, _router)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _attachRouteListener(router);
      });
    }

    ref.listen(authControllerProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user != null && prev?.valueOrNull?.id != user.id) {
        _tellerProfileId = null;
        _isFortuneTeller = false;
        unawaited(ref.read(approvedPsychicProvider.notifier).refresh());
        unawaited(_bootstrap());
      }
      if (prev?.isLoading == true && next.valueOrNull != null) {
        unawaited(_bootstrap());
        unawaited(_tryPresentNext());
      }
    });
    ref.listen<List<PsychicRequestEntity>>(psychicIncomingQueueProvider,
        (prev, next) {
      if (next.isNotEmpty && !_presenting) {
        unawaited(_tryPresentNext());
      }
    });
    ref.listen(approvedPsychicProvider, (prev, next) {
      final profile = next.profile;
      if (profile != null && profile.isUsable) {
        final wasTeller = _isFortuneTeller;
        _isFortuneTeller = true;
        _tellerProfileId = profile.id;
        if (!wasTeller || prev?.profile?.id != profile.id) {
          unawaited(ref.read(livePsychicsRepositoryProvider).setOnline(online: true));
          unawaited(_connectSse());
          unawaited(_pollApi());
        }
      } else if (next.checked) {
        _isFortuneTeller = false;
        _tellerProfileId = null;
      }
    });
    ref.listen<String?>(psychicSessionCancelSignalProvider, (prev, sessionId) {
      if (sessionId == null) return;
      if (_activePresentingSessionId == sessionId ||
          ref.read(psychicIncomingQueueProvider).any((r) => r.sessionId == sessionId)) {
        if (_presenting && _activePresentingSessionId == sessionId) {
          _dismissActiveInvite();
        } else {
          ref.read(psychicIncomingQueueProvider.notifier).remove(sessionId);
          ref.read(psychicDismissedSessionsProvider.notifier).update(
                (s) => {...s, sessionId},
              );
        }
      }
    });
    return widget.child;
  }
}
