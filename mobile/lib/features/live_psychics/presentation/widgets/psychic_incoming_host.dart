import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:canlifal_social/app/router/app_router.dart';
import 'package:canlifal_social/core/bootstrap/auth_route_paths.dart';
import 'package:canlifal_social/core/network/token_storage.dart';
import 'package:canlifal_social/features/auth/presentation/providers/auth_providers.dart';
import 'package:canlifal_social/features/live_psychics/data/services/psychic_session_store.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_request_entity.dart';
import 'package:canlifal_social/features/live_psychics/domain/entities/psychic_session_entity.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychic_incoming_controller.dart';
import 'package:canlifal_social/features/live_psychics/presentation/controllers/psychics_list_controller.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_incoming_call_dialog.dart';

/// Uygulama genelinde falcı gelen çağrı popup'ı — SSE + 2 sn poll.
class PsychicIncomingHost extends ConsumerStatefulWidget {
  const PsychicIncomingHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PsychicIncomingHost> createState() => _PsychicIncomingHostState();
}

class _PsychicIncomingHostState extends ConsumerState<PsychicIncomingHost>
    with WidgetsBindingObserver {
  Timer? _poll;
  var _presenting = false;
  String? _tellerProfileId;

  bool _isSignedIn() {
    final auth = ref.read(authControllerProvider);
    if (auth.isLoading) return false;
    return auth.valueOrNull != null;
  }

  bool _mayPresentInvites() {
    if (!_isSignedIn()) return false;
    final path =
        ref.read(goRouterProvider).routerDelegate.currentConfiguration.uri.path;
    if (_isInPsychicFlow(path)) return false;
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
      unawaited(_bootstrap());
    });
  }

  Future<void> _bootstrap() async {
    await _ensureTellerProfile();
    await _connectSse();
    _startPoll();
  }

  void _startPoll() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _pollApi());
    unawaited(_pollApi());
  }

  Future<void> _ensureTellerProfile() async {
    if (!_isSignedIn()) return;
    var approved = ref.read(approvedPsychicProvider).valueOrNull;
    if (approved?.profile == null) {
      await ref.read(approvedPsychicProvider.notifier).refresh();
      approved = ref.read(approvedPsychicProvider).valueOrNull;
    }
    final profile = approved?.profile;
    if (profile != null && profile.isApproved) {
      _tellerProfileId = profile.id;
      await ref
          .read(livePsychicsRepositoryProvider)
          .setOnline(online: true);
    }
  }

  Future<void> _connectSse() async {
    if (!_isSignedIn() || _tellerProfileId == null) return;
    final tokens = ref.read(tokenStorageProvider);
    await ref.read(psychicIncomingSseServiceProvider).connect(
          accessToken: tokens.readAccess,
          onRequest: (req) {
            if (!mounted) return;
            if (req.isPending) {
              ref.read(psychicIncomingQueueProvider.notifier).enqueue(req);
            }
          },
        );
  }

  Future<void> _pollApi() async {
    if (!mounted || _presenting || !_mayPresentInvites()) return;
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
      ref.read(psychicIncomingQueueProvider.notifier).enqueue(req);
    }
    await _tryPresentNext();
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
    await _presentInvite(next);
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

      final approved = ref.read(approvedPsychicProvider).valueOrNull?.profile;
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
      _presenting = false;
      ref.read(psychicIncomingPresentingProvider.notifier).state = false;
      if (mounted) await _tryPresentNext();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    ref.read(psychicIncomingSseServiceProvider).disconnect();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_bootstrap());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      final user = next.valueOrNull;
      if (user != null && prev?.valueOrNull?.id != user.id) {
        _tellerProfileId = null;
        unawaited(ref.read(approvedPsychicProvider.notifier).refresh());
        unawaited(_bootstrap());
      }
    });
    ref.listen<List<PsychicRequestEntity>>(psychicIncomingQueueProvider,
        (prev, next) {
      if (next.isNotEmpty && !_presenting && _mayPresentInvites()) {
        unawaited(_tryPresentNext());
      }
    });
    return widget.child;
  }
}
