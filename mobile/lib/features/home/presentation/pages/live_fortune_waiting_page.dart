import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme_colors.dart';
import '../../../../core/ui/premium/live_badge.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../live/presentation/providers/live_providers.dart';
import '../../domain/entities/live_fortune_session_entity.dart';
import '../providers/home_providers.dart';
import '../theme/home_palette.dart';
import '../widgets/live_fortune_unavailable_dialog.dart';
import 'live_fortune_session_page.dart';

/// Danışan — falcının kabulünü bekler (reklam kartı + durum poll).
class LiveFortuneWaitingPage extends ConsumerStatefulWidget {
  const LiveFortuneWaitingPage({super.key, required this.session});

  final LiveFortuneSessionEntity session;

  @override
  ConsumerState<LiveFortuneWaitingPage> createState() =>
      _LiveFortuneWaitingPageState();
}

class _LiveFortuneWaitingPageState extends ConsumerState<LiveFortuneWaitingPage> {
  Timer? _poll;
  Timer? _adTick;
  var _cancelled = false;
  var _adSeconds = 3;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => _checkStatus());
    _adTick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _adSeconds <= 0) return;
      setState(() => _adSeconds -= 1);
    });
    unawaited(_checkStatus());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _adTick?.cancel();
    super.dispose();
  }

  Future<void> _onRejected() async {
    if (_cancelled || !mounted) return;
    _cancelled = true;
    _poll?.cancel();
    await showLiveFortuneUnavailableDialog(context);
    if (!mounted) return;
    context.go('/feed');
  }

  Future<void> _checkStatus() async {
    if (!mounted || _cancelled) return;
    final status = await ref
        .read(homeRemoteProvider)
        .fetchFortuneSessionStatus(widget.session.sessionId);
    if (!mounted || status == null) return;
    if (status.isRejected) {
      await _onRejected();
      return;
    }
    if (status.isActive) {
      _cancelled = true;
      _poll?.cancel();
      ref.read(videoWebrtcSignalServiceProvider).start(
            streamId: widget.session.sessionId,
          );
      final activeSession = widget.session.copyWith(
        tellerUserId: status.tellerUserId ?? widget.session.tellerUserId,
        trtcRoomIdOverride: status.trtcRoomId,
        durationMinutes: status.durationMinutes ?? widget.session.durationMinutes,
        totalJeton: status.totalJeton ?? widget.session.totalJeton,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LiveFortuneSessionPage(session: activeSession),
        ),
      );
    }
  }

  Future<void> _cancel() async {
    _cancelled = true;
    _poll?.cancel();
    await ref
        .read(homeRemoteProvider)
        .endFortuneSession(widget.session.sessionId);
    if (!mounted) return;
    context.go('/feed');
  }

  @override
  Widget build(BuildContext context) {
    final teller = widget.session.teller;

    return Scaffold(
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
                    onPressed: _cancel,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          AppThemeColors.accentPink,
                          AppThemeColors.accentPurple,
                        ],
                      ),
                    ),
                    child: teller.avatarUrl != null && teller.avatarUrl!.isNotEmpty
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
            Wrap(
              spacing: 8,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [
                if (teller.isOnline)
                  _Pill(label: 'Çevrimiçi', color: const Color(0xFF00E676)),
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
            const SizedBox(height: 6),
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
              '💰 ${widget.session.totalJeton} jeton/seans',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 18),
                SizedBox(width: 8),
                Text(
                  'Randevu Al',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB832FF), Color(0xFFFF0080)],
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFFFFD54F),
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Reklam',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Canlı fal deneyiminiz birazdan başlayacak!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '🔮 falcı premium 🔮',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _adSeconds > 0 ? 'Reklam: ${_adSeconds}s' : 'Falcı bekleniyor…',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${widget.session.durationMinutes} dk · ${widget.session.totalJeton} jeton',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _cancel,
              child: const Text('İptal'),
            ),
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(Icons.reviews_outlined, size: 18),
                SizedBox(width: 8),
                Text(
                  'Değerlendirmeler (0)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz değerlendirme yok',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55)),
            ),
          ],
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
