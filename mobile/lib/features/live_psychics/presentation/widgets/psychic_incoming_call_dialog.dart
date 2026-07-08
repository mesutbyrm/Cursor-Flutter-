import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:canlifal_social/core/network/api_exception.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/widgets/user_avatar.dart';

import 'package:canlifal_social/features/live_psychics/domain/repositories/live_psychics_repository.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/live_psychics_providers.dart';
import 'package:canlifal_social/features/live_psychics/presentation/providers/psychic_session_cancel_signal.dart';
import 'package:canlifal_social/features/live_psychics/presentation/widgets/psychic_fortune_types.dart';
import 'package:canlifal_social/core/images/canlifal_network_image.dart';

enum PsychicIncomingDialogAction { dismissed, rejected, accepted, held }

class PsychicIncomingDialogClose {
  const PsychicIncomingDialogClose({
    required this.action,
    this.respond,
  });

  final PsychicIncomingDialogAction action;
  final PsychicRespondResult? respond;
}

/// Tam ekran gelen çağrı diyaloğu — kabul/red API çağrısı burada yapılır.
Future<PsychicIncomingDialogClose?> showPsychicIncomingCallDialog(
  BuildContext context,
  WidgetRef ref, {
  required String sessionId,
  required String clientName,
  required String fortuneType,
  required int durationMinutes,
  required int totalJeton,
  String? clientAvatarUrl,
}) {
  return showGeneralDialog<PsychicIncomingDialogClose>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Canlı fal isteği',
    barrierColor: Colors.black.withValues(alpha: 0.85),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, _) => _PsychicIncomingCallDialog(
      sessionId: sessionId,
      clientName: clientName,
      fortuneType: fortuneType,
      durationMinutes: durationMinutes,
      totalJeton: totalJeton,
      clientAvatarUrl: clientAvatarUrl,
    ),
    transitionBuilder: (ctx, anim, _, child) => FadeTransition(
      opacity: anim,
      child: child,
    ),
  );
}

class _PsychicIncomingCallDialog extends ConsumerStatefulWidget {
  const _PsychicIncomingCallDialog({
    required this.sessionId,
    required this.clientName,
    required this.fortuneType,
    required this.durationMinutes,
    required this.totalJeton,
    this.clientAvatarUrl,
  });

  final String sessionId;
  final String clientName;
  final String fortuneType;
  final int durationMinutes;
  final int totalJeton;
  final String? clientAvatarUrl;

  @override
  ConsumerState<_PsychicIncomingCallDialog> createState() =>
      _PsychicIncomingCallDialogState();
}

class _PsychicIncomingCallDialogState
    extends ConsumerState<_PsychicIncomingCallDialog> {
  var _busy = false;
  String? _busyAction;

  Future<void> _respond(String action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _busyAction = action;
    });
    try {
      final respond = await ref
          .read(livePsychicsRepositoryProvider)
          .respondSession(widget.sessionId, action: action)
          .timeout(const Duration(seconds: 28));
      if (!mounted) return;

      debugPrint(
        '[PsychicInviteDialog] $action session=${widget.sessionId} '
        'success=${respond.success} endpoint=${respond.endpoint} '
        'status=${respond.httpStatus} body=${respond.responseBody}',
      );

      if (action == 'accept') {
        if (respond.success) {
          Navigator.pop(
            context,
            PsychicIncomingDialogClose(
              action: PsychicIncomingDialogAction.accepted,
              respond: respond,
            ),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              respond.errorMessage ??
                  'Kabul sunucuya iletilemedi (${respond.httpStatus ?? '?'})',
            ),
          ),
        );
        return;
      }

      if (action == 'hold' && respond.success) {
        Navigator.pop(
          context,
          PsychicIncomingDialogClose(
            action: PsychicIncomingDialogAction.held,
            respond: respond,
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('İstek bekletildi — daha sonra kabul edebilirsiniz')),
        );
        return;
      }

      Navigator.pop(
        context,
        PsychicIncomingDialogClose(
          action: PsychicIncomingDialogAction.rejected,
          respond: respond,
        ),
      );
    } catch (e, st) {
      debugPrint(
        '[PsychicInviteDialog] $action session=${widget.sessionId} '
        'exception: $e\n$st',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiException.userMessage(e))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyAction = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<PsychicSessionCancelEvent?>(psychicSessionCancelSignalProvider,
        (prev, event) {
      if (event == null || event.sessionId != widget.sessionId || !mounted) {
        return;
      }
      if (prev?.seq == event.seq) return;
      Navigator.pop(
        context,
        const PsychicIncomingDialogClose(
          action: PsychicIncomingDialogAction.dismissed,
        ),
      );
    });

    final timeLabel = TimeOfDay.now().format(context);
    final accepting = _busy && _busyAction == 'accept';
    final holding = _busy && _busyAction == 'hold';
    final rejecting = _busy && _busyAction == 'reject';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A1450), Color(0xFF120A24), Color(0xFF0D0618)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppThemeColors.accentPink,
                        AppThemeColors.accentPurple,
                      ],
                    ),
                  ),
                  child: widget.clientAvatarUrl != null &&
                          widget.clientAvatarUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 56,
                          backgroundImage:
                              canlifalImageProvider(widget.clientAvatarUrl!),
                        )
                      : const UserAvatar(radius: 56),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Canlı Fal İsteği',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    text: widget.clientName,
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                    children: [
                      TextSpan(
                        text: '\nsizinle canlı fal için bağlanmak istiyor',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  '✨ ${psychicFortuneTypeLabel(widget.fortuneType)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${widget.durationMinutes} dakika',
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Seçilen Süre',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: Colors.white12),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${widget.totalJeton} jeton',
                              style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontWeight: FontWeight.w900,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Toplam Tutar',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 3),
                _ActionBtn(
                  label: accepting ? 'Kabul ediliyor…' : 'Kabul Et',
                  icon: Icons.call_rounded,
                  gradient: const [Color(0xFF00C853), Color(0xFF00E676)],
                  busy: accepting,
                  enabled: !_busy,
                  onTap: () => _respond('accept'),
                ),
                const SizedBox(height: 12),
                _ActionBtn(
                  label: holding ? 'Bekletiliyor…' : 'Beklet',
                  icon: Icons.pause_circle_outline_rounded,
                  gradient: const [Color(0xFFFF9800), Color(0xFFFFB74D)],
                  busy: holding,
                  enabled: !_busy,
                  onTap: () => _respond('hold'),
                ),
                const SizedBox(height: 12),
                _ActionBtn(
                  label: rejecting ? 'Reddediliyor…' : 'Reddet',
                  icon: Icons.call_end_rounded,
                  gradient: const [Color(0xFFE53935), Color(0xFFFF5252)],
                  busy: rejecting,
                  enabled: !_busy,
                  onTap: () => _respond('reject'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.pop(
                            context,
                            const PsychicIncomingDialogClose(
                              action: PsychicIncomingDialogAction.dismissed,
                            ),
                          ),
                  child: Text(
                    'Kapat',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
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

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.busy = false,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: enabled
                    ? gradient
                    : gradient.map((c) => c.withValues(alpha: 0.45)).toList(),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
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
