import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../trtc/presentation/trtc_room_manager.dart';
import '../../data/live_fortune_session_store.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import 'live_fortune_admin_ad_panel.dart';

/// Falcı kabul ettikten sonra danışana gösterilen reklam — web «Reklam: 4s».
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
  var _permissionsReady = false;

  @override
  void initState() {
    super.initState();
    unawaited(LiveFortuneSessionStore.save(widget.session));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ok = await TrtcRoomManager.requestPermissions(video: true);
      if (!mounted) return;
      setState(() => _permissionsReady = ok);
    });
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
    final teller = widget.session.teller;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0618),
        body: CosmicGalaxyBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                const SizedBox(height: 36),
                Center(
                  child: teller.avatarUrl != null && teller.avatarUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 52,
                          backgroundImage:
                              CachedNetworkImageProvider(teller.avatarUrl!),
                        )
                      : const UserAvatar(radius: 52),
                ),
                const SizedBox(height: 12),
                Text(
                  teller.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 24),
                const Row(
                  children: [
                    Icon(Icons.calendar_month_rounded, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Randevu Al',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                LiveFortuneAdminAdPanel(
                  countdownSeconds: 4,
                  onCountdownFinished: _goSession,
                  subtitle: _permissionsReady
                      ? 'Canlı fal deneyiminiz birazdan başlayacak!'
                      : 'Kamera ve mikrofon izni isteniyor…',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
