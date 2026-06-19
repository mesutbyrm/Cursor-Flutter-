import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/ui/premium/live_badge.dart';
import '../../../../core/ui/premium_2026/cosmic_galaxy_background.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/live_fortune_session_store.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../../../../core/network/token_storage.dart';
import '../providers/home_providers.dart';
import '../providers/live_fortune_room_sse_provider.dart';
import '../providers/live_fortune_feedback_provider.dart';
import '../theme/home_palette.dart';
import '../live_fortune/live_fortune_close_dialog.dart';

/// Danışan — web ile aynı «Lütfen Bekleyiniz» kartı.
class LiveFortuneWaitingPage extends ConsumerStatefulWidget {
  const LiveFortuneWaitingPage({super.key, required this.session});

  final LiveFortuneSessionEntity session;

  @override
  ConsumerState<LiveFortuneWaitingPage> createState() =>
      _LiveFortuneWaitingPageState();
}

class _LiveFortuneWaitingPageState extends ConsumerState<LiveFortuneWaitingPage>
    with SingleTickerProviderStateMixin {
  Timer? _poll;
  var _closed = false;
  var _cancelling = false;
  late final AnimationController _ring;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _checkStatus());
    unawaited(_checkStatus());
    unawaited(_connectWaitingSse());
    unawaited(LiveFortuneSessionStore.save(widget.session));
  }

  Future<void> _connectWaitingSse() async {
    final storage = ref.read(tokenStorageProvider);
    await ref.read(liveFortuneRoomSseServiceProvider).connect(
          sessionId: widget.session.sessionId,
          accessToken: storage.readAccess,
          onSessionUpdate: (status) {
            if (!mounted || _closed) return;
            if (status.isRejected) {
              unawaited(_onRejected());
              return;
            }
            if (status.isActive) {
              unawaited(_onAccepted(status));
            }
          },
          onSessionEnded: ({endedBy}) {
            if (!mounted || _closed) return;
            unawaited(_onRejected());
          },
        );
  }

  Future<void> _onAccepted(FortuneSessionStatusResult status) async {
    if (_closed || !mounted) return;
    _closed = true;
    _poll?.cancel();
    final activeSession = widget.session.copyWith(
      tellerUserId: status.tellerUserId ?? widget.session.tellerUserId,
      trtcRoomIdOverride: status.trtcRoomId,
      durationMinutes: status.durationMinutes ?? widget.session.durationMinutes,
      totalJeton: status.totalJeton ?? widget.session.totalJeton,
    );
    await LiveFortuneSessionStore.save(activeSession);
    if (!mounted) return;
    context.pushReplacement(
      '/canli-falcilar/${activeSession.teller.id}/ad-transition',
      extra: activeSession,
    );
  }

  @override
  void dispose() {
    _poll?.cancel();
    unawaited(ref.read(liveFortuneRoomSseServiceProvider).disconnect());
    _ring.dispose();
    super.dispose();
  }

  Future<void> _onCancelPressed({bool forceLocalExit = false}) async {
    if (_closed) return;
    if (_cancelling && !forceLocalExit) {
      final force = await showLiveFortuneCloseDialog(
        context,
        title: 'Yine de çık?',
        message:
            'İptal isteği sunucuya iletiliyor. Beklemeden çıkarsanız jeton iadesi gecikebilir.',
        confirmLabel: 'Çık',
      );
      if (!force || !mounted) return;
      await _exitWaiting(apiOk: false, forced: true);
      return;
    }
    if (_cancelling) return;

    final confirmed = await showLiveFortuneCloseDialog(
      context,
      title: 'Randevuyu iptal et?',
      message:
          '${widget.session.teller.name} ile randevunuzu iptal etmek istediğinize emin misiniz?',
      confirmLabel: 'İptal Et',
    );
    if (!confirmed || !mounted) return;

    setState(() => _cancelling = true);
    _poll?.cancel();

    var ended = false;
    try {
      ended = await ref
          .read(liveFortuneRepositoryProvider)
          .endSession(widget.session.sessionId);
    } catch (_) {
      ended = false;
    }

    if (!mounted) return;
    if (!ended) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sunucu iptali yanıt vermedi; yine de çıkılıyor. Jeton iadesi birkaç dakika sürebilir.',
          ),
        ),
      );
    }
    await _exitWaiting(apiOk: ended);
  }

  Future<void> _exitWaiting({required bool apiOk, bool forced = false}) async {
    if (_closed || !mounted) return;
    _closed = true;
    _poll?.cancel();
    await ref.read(liveFortuneRoomSseServiceProvider).disconnect();
    await LiveFortuneSessionStore.clear();
    ref.invalidate(coinBalanceProvider);
    if (!mounted) return;
    context.go('/canli-falcilar/${widget.session.teller.id}');
  }

  Future<void> _onRejected() async {
    if (_closed || !mounted) return;
    _closed = true;
    _poll?.cancel();
    ref.invalidate(coinBalanceProvider);
    ref.read(liveFortuneBookingFeedbackProvider.notifier).state =
        'Falcı randevunuzu reddetti';
    context.go('/canli-falcilar/${widget.session.teller.id}');
  }

  Future<void> _checkStatus() async {
    if (!mounted || _closed) return;
    final status = await ref
        .read(liveFortuneRepositoryProvider)
        .fetchSessionStatus(widget.session.sessionId);
    if (!mounted || status == null) return;

    if (status.isRejected) {
      await _onRejected();
      return;
    }

    if (status.isActive) {
      await _onAccepted(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teller = widget.session.teller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _onCancelPressed();
      },
      child: Scaffold(
        backgroundColor: HomePalette.darkBackground,
        body: CosmicGalaxyBackground(
          child: Stack(
            children: [
              SafeArea(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  children: [
                    const SizedBox(height: 36),
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
                                    radius: 52,
                                    backgroundImage: CachedNetworkImageProvider(
                                      teller.avatarUrl!,
                                    ),
                                  )
                                : const UserAvatar(radius: 52),
                          ),
                          if (teller.isOnline)
                            const Positioned(
                              right: 6,
                              bottom: 6,
                              child: LiveBadge(),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          teller.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.verified_rounded,
                          color: AppThemeColors.diamondBlue,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: [
                        if (teller.isOnline)
                          _Pill(
                            label: 'Çevrimiçi',
                            color: const Color(0xFF00E676),
                          ),
                        if (teller.rating > 0)
                          _Pill(
                            label: '★ ${teller.rating.toStringAsFixed(1)}',
                            color: const Color(0xFFFFD54F),
                            foreground: Colors.black87,
                          ),
                        _Pill(
                          label: '${teller.reviewCount} seans',
                          color: Colors.white24,
                        ),
                      ],
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
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withValues(alpha: 0.35),
                        border: Border.all(
                          color: AppThemeColors.accentPurple
                              .withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        children: [
                          RotationTransition(
                            turns: _ring,
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 3,
                                  color: AppThemeColors.accentPurple,
                                ),
                                gradient: const SweepGradient(
                                  colors: [
                                    AppThemeColors.accentPurple,
                                    AppThemeColors.accentPink,
                                    Color(0xFFFFD54F),
                                    AppThemeColors.accentPurple,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppThemeColors.accentPurple
                                        .withValues(alpha: 0.45),
                                  ),
                                  child: const Icon(
                                    Icons.videocam_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'Lütfen Bekleyiniz...',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${teller.name} randevunuzu onayladığında otomatik olarak odaya bağlanacaksınız.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _closed
                                ? null
                                : () => _exitWaiting(apiOk: false, forced: true),
                            icon: const Icon(Icons.home_rounded, size: 16),
                            label: const Text('Ana sayfaya dön'),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Falcı bekleniyor…',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed:
                                  (_closed || _cancelling) ? null : _onCancelPressed,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935),
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: _cancelling
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.close_rounded, size: 18),
                              label: Text(
                                _cancelling ? 'İptal ediliyor…' : 'İptal Et',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, top: 8),
                  child: Material(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      onPressed: _onCancelPressed,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                      tooltip: 'Geri',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    this.foreground = Colors.white,
  });

  final String label;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: color == Colors.white24 ? 1 : 0.2),
        borderRadius: BorderRadius.circular(20),
        border: color == Colors.white24
            ? null
            : Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}
