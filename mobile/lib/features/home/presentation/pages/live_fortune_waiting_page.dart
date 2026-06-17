import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/ui/premium/live_badge.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';
import '../widgets/live_fortune_unavailable_dialog.dart';
import '../live_fortune/live_fortune_admin_ad_panel.dart';
import '../live_fortune/live_fortune_ad_transition_page.dart';
import '../live_fortune/live_fortune_flow.dart';

/// Danışan — randevu sonrası falcı kabulünü bekler; admin reklamı gösterilir.
class LiveFortuneWaitingPage extends ConsumerStatefulWidget {
  const LiveFortuneWaitingPage({super.key, required this.session});

  final LiveFortuneSessionEntity session;

  @override
  ConsumerState<LiveFortuneWaitingPage> createState() =>
      _LiveFortuneWaitingPageState();
}

class _LiveFortuneWaitingPageState extends ConsumerState<LiveFortuneWaitingPage> {
  Timer? _poll;
  var _closed = false;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _checkStatus());
    unawaited(_checkStatus());
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _onClosePressed() async {
    if (_closed) return;
    final ok = await LiveFortuneFlow.cancelWaiting(
      context: context,
      ref: ref,
      sessionId: widget.session.sessionId,
      tellerName: widget.session.teller.name,
    );
    if (ok) _closed = true;
  }

  Future<void> _onRejected() async {
    if (_closed || !mounted) return;
    _closed = true;
    _poll?.cancel();
    ref.invalidate(coinBalanceProvider);
    await showLiveFortuneUnavailableDialog(
      context,
      tellerName: widget.session.teller.name,
    );
  }

  Future<void> _checkStatus() async {
    if (!mounted || _closed) return;
    final status = await ref
        .read(homeRemoteProvider)
        .fetchFortuneSessionStatus(widget.session.sessionId);
    if (!mounted || status == null) return;

    if (status.isRejected) {
      await _onRejected();
      return;
    }

    if (status.isActive) {
      _closed = true;
      _poll?.cancel();
      final activeSession = widget.session.copyWith(
        tellerUserId: status.tellerUserId ?? widget.session.tellerUserId,
        trtcRoomIdOverride: status.trtcRoomId,
        durationMinutes:
            status.durationMinutes ?? widget.session.durationMinutes,
        totalJeton: status.totalJeton ?? widget.session.totalJeton,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LiveFortuneAdTransitionPage(session: activeSession),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final teller = widget.session.teller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onClosePressed();
      },
      child: Scaffold(
        backgroundColor: HomePalette.darkBackground,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Row(
                children: [
                  Material(
                    color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      onPressed: _onClosePressed,
                      icon: const Icon(Icons.close_rounded, size: 20),
                      tooltip: 'Kapat',
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _onClosePressed,
                    child: const Text('İptal'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
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
                      child: teller.avatarUrl != null &&
                              teller.avatarUrl!.isNotEmpty
                          ? CircleAvatar(
                              radius: 44,
                              backgroundImage:
                                  CachedNetworkImageProvider(teller.avatarUrl!),
                            )
                          : const UserAvatar(radius: 44),
                    ),
                    if (teller.isOnline)
                      const Positioned(
                        right: 4,
                        bottom: 4,
                        child: LiveBadge(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    teller.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.verified_rounded,
                    color: AppThemeColors.diamondBlue,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                teller.displayCategory,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.session.durationMinutes} dk · ${widget.session.totalJeton} jeton',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'İstek gönderildi',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Falcının kabul etmesi bekleniyor…',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 14),
              LiveFortuneAdminAdPanel(
                subtitle:
                    'Falcı kabul edene kadar admin reklamı gösterilir.',
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: _onClosePressed,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Randevuyu iptal et'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
