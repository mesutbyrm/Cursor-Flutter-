import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import 'live_fortune_admin_ad_panel.dart';

/// Falcı kabul ettikten sonra danışana gösterilen reklam geçişi (ekran 3).
class LiveFortuneAdTransitionPage extends ConsumerStatefulWidget {
  const LiveFortuneAdTransitionPage({super.key, required this.session});

  final LiveFortuneSessionEntity session;

  @override
  ConsumerState<LiveFortuneAdTransitionPage> createState() =>
      _LiveFortuneAdTransitionPageState();
}

class _LiveFortuneAdTransitionPageState
    extends ConsumerState<LiveFortuneAdTransitionPage> {
  var _navigated = false;

  @override
  void initState() {
    super.initState();
    ref.read(videoWebrtcSignalServiceProvider).start(
          streamId: widget.session.sessionId,
        );
  }

  void _goSession() {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.pushReplacement(
      '/canli-falcilar/${widget.session.teller.id}/session',
      extra: widget.session,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0618),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                const Text(
                  'Falcı kabul etti!',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.session.teller.name} ile bağlantı kuruluyor…',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: LiveFortuneAdminAdPanel(
                    countdownSeconds: 3,
                    onCountdownFinished: _goSession,
                    subtitle: 'Seansınız birazdan başlayacak!',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
