import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../live_psychics/presentation/widgets/psychic_fortune_types.dart';
import '../data/video_call_invitation_service.dart';
import '../domain/video_call_invitation.dart';
import 'video_call_provider.dart';

/// Tam ekran gelen görüntülü çağrı UI — Kabul / Reddet / Meşgul.
class IncomingVideoCallScreen extends ConsumerStatefulWidget {
  const IncomingVideoCallScreen({
    super.key,
    required this.invitation,
    required this.onResponse,
  });

  final VideoCallInvitation invitation;
  final ValueChanged<VideoCallResponse> onResponse;

  @override
  ConsumerState<IncomingVideoCallScreen> createState() =>
      _IncomingVideoCallScreenState();
}

class _IncomingVideoCallScreenState extends ConsumerState<IncomingVideoCallScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Timer? _countdown;
  var _secondsLeft = VideoCallInvitationService.callTimeout.inSeconds;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsLeft = (_secondsLeft - 1).clamp(0, 30);
      });
      if (_secondsLeft <= 0) {
        widget.onResponse(VideoCallResponse.timeout);
      }
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invite = widget.invitation;
    final scale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );

    return Material(
      color: Colors.black.withValues(alpha: 0.92),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Text(
              'Gelen görüntülü arama',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_secondsLeft sn',
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 14,
              ),
            ),
            const Spacer(),
            ScaleTransition(
              scale: scale,
              child: Hero(
                tag: 'video_call_avatar_${invite.callId}',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF00E676),
                      width: 3,
                    ),
                  ),
                  child: UserAvatar(
                    url: invite.callerAvatarUrl,
                    radius: 56,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              invite.callerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '✨ ${psychicFortuneTypeLabel(invite.displayCategory)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (invite.durationMinutes > 0) ...[
              const SizedBox(height: 12),
              Text(
                '${invite.durationMinutes} dk · ${invite.totalJeton} jeton',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ],
            if (invite.pricePerMinute != null) ...[
              const SizedBox(height: 4),
              Text(
                'Dakika ücreti: ${invite.pricePerMinute!.toStringAsFixed(0)} jeton',
                style: TextStyle(
                  color: Colors.amber.shade200,
                  fontSize: 13,
                ),
              ),
            ],
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.call_end_rounded,
                    label: 'Reddet',
                    color: const Color(0xFFE53935),
                    onTap: () => widget.onResponse(VideoCallResponse.reject),
                  ),
                  _ActionButton(
                    icon: Icons.phone_disabled_rounded,
                    label: 'Meşgul',
                    color: const Color(0xFFFF9800),
                    onTap: () => widget.onResponse(VideoCallResponse.busy),
                  ),
                  _ActionButton(
                    icon: Icons.videocam_rounded,
                    label: 'Kabul',
                    color: const Color(0xFF00E676),
                    onTap: () => widget.onResponse(VideoCallResponse.accept),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// Uygulama genelinde gelen çağrı overlay'i.
class VideoCallIncomingHost extends ConsumerWidget {
  const VideoCallIncomingHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(videoCallPsychicBridgeProvider);
    final callState = ref.watch(videoCallProvider);
    final active = callState.active;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (active != null && !callState.presenting)
          IncomingVideoCallScreen(
            invitation: active,
            onResponse: (r) {
              ref.read(videoCallProvider.notifier).respond(active.callId, r);
            },
          ),
      ],
    );
  }
}
