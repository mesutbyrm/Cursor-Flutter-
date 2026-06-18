import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/bootstrap/auth_route_paths.dart';
import '../../../../core/network/token_storage.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../data/services/live_fortune_request_sse_service.dart';
import '../../data/services/live_fortune_teller_incoming_sse_service.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../live_fortune/fortune_invite_coordinator.dart';
import '../live_fortune/live_fortune_flow.dart';
import '../live_fortune/live_fortune_teller_invite_flow.dart';
import '../providers/fortune_incoming_invite_provider.dart';
import '../providers/fortune_live_event_bus.dart';
import '../providers/home_providers.dart';
import '../providers/teller_profile_provider.dart';
import '../../../agency/presentation/providers/agency_providers.dart';
import 'live_fortune_invite_action.dart';

final liveFortuneRequestSseServiceProvider =
    Provider<LiveFortuneRequestSseService>((ref) {
  final service = LiveFortuneRequestSseService();
  ref.onDispose(service.disconnect);
  return service;
});

final liveFortuneTellerIncomingSseServiceProvider =
    Provider<LiveFortuneTellerIncomingSseService>((ref) {
  final service = LiveFortuneTellerIncomingSseService();
  ref.onDispose(service.disconnect);
  return service;
});

/// Uygulama genelinde falcı davet popup'ı — SSE, poll ve push.
class FortuneIncomingInviteHost extends ConsumerStatefulWidget {
  const FortuneIncomingInviteHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FortuneIncomingInviteHost> createState() =>
      _FortuneIncomingInviteHostState();
}

class _FortuneIncomingInviteHostState
    extends ConsumerState<FortuneIncomingInviteHost>
    with WidgetsBindingObserver {
  Timer? _poll;
  StreamSubscription<FortuneIncomingSession>? _sseBusSub;
  var _presenting = false;
  var _inviteUiReady = false;
  var _tellerOnlineSet = false;
  var _isFortuneTeller = false;
  String? _tellerProfileId;
  String? _sseRoomId;
  final Set<String> _dismissed = {};

  bool _isSignedIn() {
    if (!_inviteUiReady) return false;
    final auth = ref.read(authControllerProvider);
    if (auth.isLoading) return false;
    return auth.valueOrNull != null;
  }

  bool _mayPresentInvites() {
    if (!_isSignedIn()) return false;
    final path =
        ref.read(goRouterProvider).routerDelegate.currentConfiguration.uri.path;
    if (path.contains('/canli-falcilar') && path.contains('/session')) {
      return false;
    }
    return !AuthRoutePaths.isPublicAuthPath(path);
  }

  bool _mayRunTellerBackgroundSync() {
    if (!_isSignedIn()) return false;
    return !AuthRoutePaths.isPublicAuthPath(
      ref.read(goRouterProvider).routerDelegate.currentConfiguration.uri.path,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _inviteUiReady = true);
      FortuneInviteCoordinator.onRequestPresent = () {
        if (!mounted) return;
        unawaited(_tryPresentNext());
      };
      _sseBusSub = ref
          .read(fortuneLiveEventBusProvider)
          .stream
          .listen(_onSseFortuneRequest);
      unawaited(_bootstrapTeller());
    });
  }

  void _startPoll() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _pollApi());
    unawaited(_pollApi());
  }

  @override
  void dispose() {
    FortuneInviteCoordinator.onRequestPresent = null;
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _sseBusSub?.cancel();
    ref.read(liveFortuneRequestSseServiceProvider).disconnect();
    ref.read(liveFortuneTellerIncomingSseServiceProvider).disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_bootstrapTeller());
      unawaited(_pollApi());
    }
  }

  Future<void> _bootstrapTeller() async {
    await _ensureTellerOnline();
    await _connectFortuneSse();
    _startPoll();
    await _resumeActiveClientSessions();
  }

  Future<void> _resumeActiveClientSessions() async {
    if (!_mayPresentInvites()) return;
    final path =
        ref.read(goRouterProvider).routerDelegate.currentConfiguration.uri.path;
    if (path.contains('/canli-falcilar') && path.contains('/session')) {
      return;
    }
    await LiveFortuneFlow.resumeActiveClientSessions(
      router: ref.read(goRouterProvider),
      repo: ref.read(liveFortuneRepositoryProvider),
    );
  }

  Future<void> _ensureTellerOnline() async {
    if (!_mayRunTellerBackgroundSync()) return;
    final approved = ref.read(approvedTellerProvider);
    var profile = approved.profile;
    if (profile == null) {
      await ref.read(approvedTellerProvider.notifier).refresh();
      profile = ref.read(approvedTellerProvider).profile;
    }
    if (profile == null) {
      final repo = ref.read(liveFortuneRepositoryProvider);
      final userId = ref.read(authControllerProvider).valueOrNull?.id;
      profile = await repo.fetchMyProfile();
      if (profile == null && userId != null) {
        final tellers = await repo.fetchTellers();
        for (final t in tellers) {
          if (t.userId == userId || t.id == userId) {
            profile = t;
            break;
          }
        }
      }
    }
    if (profile == null || !profile.isUsable) {
      _isFortuneTeller = false;
      _tellerProfileId = null;
      return;
    }
    _isFortuneTeller = true;
    _tellerProfileId = profile.id;
    final ok = await ref.read(liveFortuneRepositoryProvider).setOnline(online: true);
    if (ok) _tellerOnlineSet = true;
  }

  Future<void> _connectFortuneSse() async {
    if (!_mayRunTellerBackgroundSync()) return;

    if (_isFortuneTeller) {
      final tokens = ref.read(tokenStorageProvider);
      await ref.read(liveFortuneTellerIncomingSseServiceProvider).connect(
            accessToken: tokens.readAccess,
            onRequest: _onSseFortuneRequest,
          );
    }

    final roomId = await _resolveTellerSseRoomId();
    if (roomId == null || roomId.isEmpty) {
      await ref.read(liveFortuneRequestSseServiceProvider).disconnect();
      _sseRoomId = null;
      return;
    }
    if (_sseRoomId == roomId) return;
    _sseRoomId = roomId;
    final tokens = ref.read(tokenStorageProvider);
    await ref.read(liveFortuneRequestSseServiceProvider).connect(
          roomId: roomId,
          accessToken: tokens.readAccess,
          onRequest: _onSseFortuneRequest,
        );
  }

  Future<String?> _resolveTellerSseRoomId() async {
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    if (userId == null || userId.isEmpty) return null;
    try {
      final streams = await ref.read(liveStreamsProvider.future);
      for (final stream in streams) {
        if (stream.isLive &&
            stream.hostUserId == userId &&
            stream.id.isNotEmpty) {
          return stream.id;
        }
      }
    } catch (_) {}
    try {
      final rooms = await ref.read(voiceRoomsProvider.future);
      for (final room in rooms) {
        if (room.ownerId == userId) {
          final key = room.apiRoomKey.isNotEmpty ? room.apiRoomKey : room.id;
          if (key.isNotEmpty) return key;
        }
      }
    } catch (_) {}
    return null;
  }

  void _onSseFortuneRequest(FortuneIncomingSession session) {
    if (!mounted || !_mayRunTellerBackgroundSync()) return;
    if (!_isPendingInvite(session)) return;
    ref.read(fortuneIncomingInviteProvider.notifier).enqueue(session);
  }

  bool _isPendingInvite(FortuneIncomingSession session) {
    final status = session.status.toLowerCase();
    final response = session.tellerResponse.toLowerCase();
    if (response == 'accepted' ||
        response == 'rejected' ||
        response == 'declined' ||
        response == 'cancelled' ||
        status == 'active' ||
        status == 'ended' ||
        status == 'completed' ||
        status == 'cancelled' ||
        status == 'rejected') {
      return false;
    }
    return response.isEmpty ||
        response == 'pending' ||
        response == 'held' ||
        response == 'waiting' ||
        response == 'requested' ||
        status == 'pending' ||
        status == 'waiting' ||
        status == 'requested' ||
        status == 'new' ||
        status == 'open';
  }

  Future<void> _pollApi() async {
    if (!mounted || _presenting || !_mayRunTellerBackgroundSync()) return;

    if (_tellerProfileId == null) {
      await _ensureTellerOnline();
    }

    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    final incoming = await ref
        .read(liveFortuneRepositoryProvider)
        .fetchIncomingSessions(
          currentUserId: userId,
          tellerProfileId: _tellerProfileId,
        );
    if (!mounted) return;
    for (final req in incoming) {
      if (!_isPendingInvite(req)) continue;
      ref.read(fortuneIncomingInviteProvider.notifier).enqueue(req);
    }
    if (_mayPresentInvites()) {
      await _tryPresentNext();
    }
  }

  Future<void> _tryPresentNext() async {
    if (!mounted || _presenting || !_mayPresentInvites()) return;
    final next = ref.read(fortuneIncomingInviteProvider.notifier).takeNext();
    if (next == null) return;
    if (_dismissed.contains(next.sessionId)) {
      await _tryPresentNext();
      return;
    }
    await _presentInvite(next);
  }

  Future<void> _presentInvite(FortuneIncomingSession req) async {
    if (!mounted || !_mayPresentInvites()) {
      ref.read(fortuneIncomingInviteProvider.notifier).enqueue(req);
      return;
    }
    _presenting = true;
    try {
      FortuneInviteCoordinator.markDialogShown(req.sessionId);
      final action = await LiveFortuneTellerInviteFlow.showInviteDialog(req);
      if (!mounted) return;

      if (action == null) {
        ref.read(fortuneIncomingInviteProvider.notifier).enqueue(req);
        return;
      }

      if (action == LiveFortuneInviteAction.reject) {
        await ref.read(liveFortuneRepositoryProvider).respondSession(
              req.sessionId,
              action: 'reject',
            );
        _dismissed.add(req.sessionId);
        return;
      }

      if (action == LiveFortuneInviteAction.hold) {
        ref.read(fortuneIncomingInviteProvider.notifier).enqueue(req);
        return;
      }

      final respond = await ref
          .read(liveFortuneRepositoryProvider)
          .respondSessionDetailed(req.sessionId, action: 'accept');
      if (!mounted) return;
      final navCtx = rootNavigatorKey.currentContext;
      if (!respond.success) {
        if (navCtx != null && navCtx.mounted) {
          ScaffoldMessenger.of(navCtx).showSnackBar(
            const SnackBar(
              content: Text('Kabul sunucuya iletilemedi. Tekrar deneyin.'),
            ),
          );
        }
        ref.read(fortuneIncomingInviteProvider.notifier).enqueue(req);
        return;
      }

      final opened = await LiveFortuneTellerInviteFlow.openSessionAfterAccept(
        ref: ref,
        req: req,
        roomIdOverride: respond.roomId,
      );
      if (opened) _dismissed.add(req.sessionId);
    } finally {
      _presenting = false;
      if (mounted) await _tryPresentNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user != null && (prev?.valueOrNull?.id != user.id)) {
        _tellerOnlineSet = false;
        _sseRoomId = null;
        unawaited(ref.read(approvedTellerProvider.notifier).refresh());
        unawaited(ref.read(approvedAgencyProvider.notifier).refresh());
        unawaited(_bootstrapTeller());
      }
    });
    ref.listen<List<FortuneIncomingSession>>(fortuneIncomingInviteProvider,
        (prev, next) {
      if (next.isNotEmpty && !_presenting && _mayPresentInvites()) {
        unawaited(_tryPresentNext());
      }
    });
    return widget.child;
  }
}
