import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../../domain/entities/live_fortune_teller_entity.dart';
import '../providers/fortune_incoming_invite_provider.dart';
import '../providers/home_providers.dart';
import 'live_fortune_invite_sheet.dart';

/// Uygulama genelinde falcı davet popup'ı — push ve poll kaynaklı.
class FortuneIncomingInviteHost extends ConsumerStatefulWidget {
  const FortuneIncomingInviteHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FortuneIncomingInviteHost> createState() =>
      _FortuneIncomingInviteHostState();
}

class _FortuneIncomingInviteHostState
    extends ConsumerState<FortuneIncomingInviteHost> {
  Timer? _poll;
  var _presenting = false;
  final Set<String> _dismissed = {};

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _pollApi());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authControllerProvider).valueOrNull;
      if (user == null) return;
      _pollApi();
      _tryPresentNext();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  bool _isPendingInvite(FortuneIncomingSession session) {
    final status = session.status.toLowerCase();
    final response = session.tellerResponse.toLowerCase();
    if (response == 'accepted' ||
        response == 'rejected' ||
        status == 'active' ||
        status == 'ended') {
      return false;
    }
    return response == 'pending' || status == 'pending' || status == 'waiting';
  }

  Future<void> _pollApi() async {
    if (!mounted || _presenting) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    final incoming =
        await ref.read(homeRemoteProvider).fetchIncomingFortuneSessions();
    if (!mounted) return;
    for (final req in incoming) {
      if (!_isPendingInvite(req)) continue;
      ref.read(fortuneIncomingInviteProvider.notifier).enqueue(req);
    }
    await _tryPresentNext();
  }

  Future<void> _tryPresentNext() async {
    if (!mounted || _presenting) return;
    if (ref.read(authControllerProvider).valueOrNull == null) return;
    final next = ref.read(fortuneIncomingInviteProvider.notifier).takeNext();
    if (next == null) return;
    if (_dismissed.contains(next.sessionId)) {
      await _tryPresentNext();
      return;
    }
    await _presentInvite(next);
  }

  Future<void> _presentInvite(FortuneIncomingSession req) async {
    if (!mounted) return;
    _presenting = true;
    try {
      final navCtx = rootNavigatorKey.currentContext;
      if (navCtx == null || !navCtx.mounted) {
        ref.read(fortuneIncomingInviteProvider.notifier).enqueue(req);
        return;
      }

      final action = await showLiveFortuneTellerInviteSheet(
        navCtx,
        clientName: req.clientName,
        category: req.category,
        durationMinutes: req.durationMinutes,
        totalJeton: req.totalJeton,
      );
      if (!mounted) return;

      if (action == null) {
        await ref.read(homeRemoteProvider).respondFortuneSession(
              req.sessionId,
              action: 'hold',
            );
        _dismissed.add(req.sessionId);
        return;
      }
      if (action == false) {
        await ref.read(homeRemoteProvider).respondFortuneSession(
              req.sessionId,
              action: 'reject',
            );
        _dismissed.add(req.sessionId);
        return;
      }

      final ok = await ref.read(homeRemoteProvider).respondFortuneSession(
            req.sessionId,
            action: 'accept',
          );
      if (!mounted || !ok) return;

      final user = ref.read(authControllerProvider).valueOrNull;
      final tellerId = req.tellerId.trim();
      LiveFortuneTellerEntity? teller;
      if (tellerId.isNotEmpty) {
        teller = await ref.read(homeRemoteProvider).fetchLiveFortuneTeller(tellerId);
      }
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
        durationMinutes: req.durationMinutes,
        totalJeton: req.totalJeton,
        tellerUserId: teller.trtcUserId,
        clientId: req.clientId,
        isClient: false,
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
    ref.listen<List<FortuneIncomingSession>>(fortuneIncomingInviteProvider,
        (prev, next) {
      if (next.isNotEmpty && !_presenting) {
        unawaited(_tryPresentNext());
      }
    });
    return widget.child;
  }
}
