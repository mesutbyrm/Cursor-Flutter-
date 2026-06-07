import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../providers/home_providers.dart';
import 'live_fortune_invite_sheet.dart';

/// Giriş yapan falcı hesabında gelen canlı fal isteklerini dinler.
class FortuneTellerIncomingListener extends ConsumerStatefulWidget {
  const FortuneTellerIncomingListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FortuneTellerIncomingListener> createState() =>
      _FortuneTellerIncomingListenerState();
}

class _FortuneTellerIncomingListenerState
    extends ConsumerState<FortuneTellerIncomingListener> {
  Timer? _poll;
  final Set<String> _shown = {};
  var _handling = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _tick() async {
    if (!mounted || _handling) return;
    final user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) return;

    final incoming =
        await ref.read(homeRemoteProvider).fetchIncomingFortuneSessions();
    if (!mounted || incoming.isEmpty) return;

    for (final req in incoming) {
      if (_shown.contains(req.sessionId)) continue;
      _shown.add(req.sessionId);
      await _handleIncoming(req);
      break;
    }
  }

  Future<void> _handleIncoming(FortuneIncomingSession req) async {
    if (!mounted) return;
    _handling = true;
    try {
      final teller = await ref
          .read(homeRemoteProvider)
          .fetchLiveFortuneTeller(req.tellerId);
      if (!mounted || teller == null) return;

      final action = await showLiveFortuneTellerInviteSheet(
        context,
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
        return;
      }
      if (action == false) {
        await ref.read(homeRemoteProvider).respondFortuneSession(
              req.sessionId,
              action: 'reject',
            );
        return;
      }

      final ok = await ref.read(homeRemoteProvider).respondFortuneSession(
            req.sessionId,
            action: 'accept',
          );
      if (!mounted || !ok) return;

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
      await context.push(
        '/canli-falcilar/${teller.id}/session',
        extra: session,
      );
    } finally {
      _handling = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
