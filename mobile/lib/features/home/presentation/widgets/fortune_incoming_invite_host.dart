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
import '../../domain/entities/live_fortune_session_entity.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../live_fortune/live_fortune_close_dialog.dart';
import '../live_fortune/live_fortune_flow.dart';
import '../providers/fortune_incoming_invite_provider.dart';
import '../providers/fortune_live_event_bus.dart';
import '../providers/home_providers.dart';
import 'fortune_request_dialog.dart';
import 'live_fortune_invite_action.dart';
import 'live_fortune_session_start_sheet.dart';

final liveFortuneRequestSseServiceProvider =
    Provider<LiveFortuneRequestSseService>((ref) {
  final service = LiveFortuneRequestSseService();
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
  String? _tellerProfileId;
  String? _sseRoomId;
  final Set<String> _dismissed = {};

  bool _mayPresentInvites() {
    if (!_inviteUiReady) return false;
    final auth = ref.read(authControllerProvider);
    if (auth.isLoading) return false;
    if (auth.valueOrNull == null) return false;
    final router = ref.read(goRouterProvider);
    final path = router.routerDelegate.currentConfiguration.uri.path;
    return !AuthRoutePaths.isPublicAuthPath(path);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _pollApi());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _inviteUiReady = true);
      _sseBusSub = ref
          .read(fortuneLiveEventBusProvider)
          .stream
          .listen(_onSseFortuneRequest);
      unawaited(_bootstrapTeller());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    _sseBusSub?.cancel();
    ref.read(liveFortuneRequestSseServiceProvider).disconnect();
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
    await _pollApi();
  }

  Future<void> _ensureTellerOnline() async {
    if (!_mayPresentInvites()) return;
    final remote = ref.read(homeRemoteProvider);
    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    var profile = await remote.fetchMyFortuneTellerProfile();
    if (profile == null && userId != null) {
      final tellers = await remote.fetchLiveFortuneTellers();
      for (final t in tellers) {
        if (t.userId == userId || t.id == userId) {
          profile = t;
          break;
        }
      }
    }
    if (profile == null) return;
    _tellerProfileId = profile.id;
    if (_tellerOnlineSet) return;
    final ok = await remote.setFortuneTellerOnline(online: true);
    if (ok) _tellerOnlineSet = true;
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

  Future<void> _connectFortuneSse() async {
    if (!_mayPresentInvites()) return;
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

  void _onSseFortuneRequest(FortuneIncomingSession session) {
    if (!mounted || !_mayPresentInvites()) return;
    if (!_isPendingInvite(session)) return;
    ref.read(fortuneIncomingInviteProvider.notifier).enqueue(session);
    unawaited(_tryPresentNext());
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
    if (!mounted || _presenting || !_mayPresentInvites()) return;

    final userId = ref.read(authControllerProvider).valueOrNull?.id;
    final incoming = await ref
        .read(homeRemoteProvider)
        .fetchIncomingFortuneSessions(
          currentUserId: userId,
          tellerProfileId: _tellerProfileId,
        );
    if (!mounted) return;
    for (final req in incoming) {
      if (!_isPendingInvite(req)) continue;
      ref.read(fortuneIncomingInviteProvider.notifier).enqueue(req);
    }
    await _tryPresentNext();
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
    if (!mounted || !_mayPresentInvites()) return;
    _presenting = true;
    try {
      final navCtx = rootNavigatorKey.currentContext;
      if (navCtx == null || !navCtx.mounted) {
        ref.read(fortuneIncomingInviteProvider.notifier).enqueue(req);
        return;
      }

      final action = await showFortuneRequestDialog(
        navCtx,
        clientName: req.clientName,
        category: req.category,
        durationMinutes: req.durationMinutes,
        totalJeton: req.totalJeton,
      );
      if (!mounted) return;

      if (action == null) {
        ref.read(fortuneIncomingInviteProvider.notifier).enqueue(req);
        return;
      }

      if (action == LiveFortuneInviteAction.reject) {
        await ref.read(homeRemoteProvider).respondFortuneSession(
              req.sessionId,
              action: 'reject',
            );
        _dismissed.add(req.sessionId);
        if (mounted && navCtx.mounted) {
          liveFortuneExitToHome(navCtx);
        }
        return;
      }

      if (action == LiveFortuneInviteAction.hold) {
        await ref.read(homeRemoteProvider).respondFortuneSession(
              req.sessionId,
              action: 'hold',
            );
        _dismissed.add(req.sessionId);
        return;
      }

      final ok = await ref.read(homeRemoteProvider).respondFortuneSession(
            req.sessionId,
            action: 'accept',
          );
      if (!mounted || !ok) return;

      final roomPreview = await ref
          .read(homeRemoteProvider)
          .fetchRoomInfo(req.sessionId);
      final clientJeton = roomPreview?.userJetonBalance ?? req.totalJeton;

      final startChoice = await showLiveFortuneSessionStartSheet(
        navCtx,
        clientName: req.clientName,
        clientJetonBalance: clientJeton,
      );
      if (!mounted || startChoice == null) {
        await ref.read(homeRemoteProvider).respondFortuneSession(
              req.sessionId,
              action: 'reject',
            );
        if (navCtx.mounted) liveFortuneExitToHome(navCtx);
        return;
      }

      if (startChoice.durationMinutes > 0) {
        await ref.read(homeRemoteProvider).tellerAddSessionTime(
              sessionId: req.sessionId,
              minutes: startChoice.durationMinutes,
            );
      }

      await ref.read(homeRemoteProvider).roomAction(
            req.sessionId,
            'start_timer',
          );

      final status = await ref
          .read(homeRemoteProvider)
          .fetchFortuneSessionStatus(req.sessionId);

      final user = ref.read(authControllerProvider).valueOrNull;
      final tellerId = req.tellerId.trim();
      LiveFortuneTellerEntity? teller;
      if (tellerId.isNotEmpty) {
        teller = await ref.read(homeRemoteProvider).fetchLiveFortuneTeller(tellerId);
      }
      teller ??= await ref.read(homeRemoteProvider).fetchMyFortuneTellerProfile();
      teller ??= LiveFortuneTellerEntity(
        id: tellerId.isNotEmpty ? tellerId : (user?.id ?? 'teller'),
        userId: user?.id,
        name: user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : (user?.username ?? 'Falcı'),
        isOnline: true,
      );

      final session = LiveFortuneSessionEntity(
        sessionId: req.sessionId,
        teller: teller,
        durationMinutes: startChoice.durationMinutes > 0
            ? startChoice.durationMinutes
            : (status?.durationMinutes ?? req.durationMinutes),
        totalJeton: startChoice.totalJeton > 0
            ? startChoice.totalJeton
            : (status?.totalJeton ?? req.totalJeton),
        tellerUserId: status?.tellerUserId ?? req.tellerUserId ?? teller.trtcUserId,
        clientId: req.clientId,
        isClient: false,
        trtcRoomIdOverride: status?.trtcRoomId,
      );
      ref.read(videoWebrtcSignalServiceProvider).start(
            streamId: session.sessionId,
          );
      if (!mounted) return;
      await navCtx.push(
        '/canli-falcilar/${teller.id}/session',
        extra: session,
      );
      _dismissed.add(req.sessionId);
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
