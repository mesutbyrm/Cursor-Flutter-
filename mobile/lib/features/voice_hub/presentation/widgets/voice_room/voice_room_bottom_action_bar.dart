import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../theme/voice_room_tokens.dart';

/// Alt menü: Hoparlör/Kulaklık · Ayarlar · Mikrofon · Hediye · Davet.
class VoiceRoomBottomActionBar extends StatelessWidget {
  const VoiceRoomBottomActionBar({
    super.key,
    required this.headphonesOn,
    required this.onToggleAudioOutput,
    required this.onSettings,
    required this.micOn,
    required this.micEnabled,
    required this.onMicToggle,
    required this.onGift,
    required this.onInvite,
    this.showSettings = true,
    this.onSpeakRequest,
    this.speakRequestPending = false,
    this.showSpeakRequest = false,
  });

  final bool headphonesOn;
  final VoidCallback onToggleAudioOutput;
  final VoidCallback onSettings;
  final bool showSettings;
  final bool micOn;
  final bool micEnabled;
  final VoidCallback onMicToggle;
  final VoidCallback onGift;
  final VoidCallback onInvite;
  final VoidCallback? onSpeakRequest;
  final bool speakRequestPending;
  final bool showSpeakRequest;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final useBlur =
        !kIsWeb && defaultTargetPlatform != TargetPlatform.android;

    final bar = Container(
      padding: EdgeInsets.fromLTRB(4, 8, 4, 10 + bottom),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: useBlur ? 0.72 : 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          _SpeakerAction(
            headphonesOn: headphonesOn,
            onTap: onToggleAudioOutput,
          ),
          if (showSettings) _SettingsAction(onTap: onSettings),
          if (showSpeakRequest && onSpeakRequest != null)
            _SpeakRequestAction(
              pending: speakRequestPending,
              onTap: onSpeakRequest!,
            ),
          Expanded(
            child: Center(
              child: _CenterMicButton(
                micOn: micOn,
                enabled: micEnabled,
                onTap: onMicToggle,
              ),
            ),
          ),
          _SideAction(
            emoji: '🎁',
            label: 'Hediye',
            color: AppThemeColors.coinGold,
            onTap: onGift,
          ),
          _SideAction(
            emoji: '📨',
            label: 'Davet',
            onTap: onInvite,
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: useBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: bar,
              )
            : bar,
      ),
    );
  }
}

class _SpeakRequestAction extends StatelessWidget {
  const _SpeakRequestAction({
    required this.pending,
    required this.onTap,
  });

  final bool pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = pending ? VoiceRoomTokens.neonPink : VoiceRoomTokens.neonBlue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pending ? Icons.front_hand_rounded : Icons.back_hand_outlined,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                pending ? 'Bekliyor' : 'El kaldır',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.settings_rounded, color: VoiceRoomTokens.neonBlue, size: 24),
              const SizedBox(height: 2),
              Text(
                'Ayarlar',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeakerAction extends StatelessWidget {
  const _SpeakerAction({
    required this.headphonesOn,
    required this.onTap,
  });

  final bool headphonesOn;
  final VoidCallback onTap;

  static const _green = Color(0xFF22C55E);
  static const _red = Color(0xFFEF4444);

  @override
  Widget build(BuildContext context) {
    final on = headphonesOn;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 56,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                on ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: on ? _green : _red,
                size: 24,
              ),
              const SizedBox(height: 2),
              Text(
                on ? 'Açık' : 'Kapalı',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: on ? _green : _red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  const _SideAction({
    required this.emoji,
    required this.label,
    required this.onTap,
    this.color,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 52,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20, height: 1)),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: color ?? Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterMicButton extends StatefulWidget {
  const _CenterMicButton({
    required this.micOn,
    required this.enabled,
    required this.onTap,
  });

  final bool micOn;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_CenterMicButton> createState() => _CenterMicButtonState();
}

class _CenterMicButtonState extends State<_CenterMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -12),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final glow = widget.micOn && widget.enabled
                ? 16 + _pulse.value * 12
                : 0.0;
            return Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.enabled
                    ? VoiceRoomTokens.micFabGradient
                    : LinearGradient(
                        colors: [
                          Colors.grey.shade700,
                          Colors.grey.shade900,
                        ],
                      ),
                boxShadow: glow > 0
                    ? VoiceRoomTokens.neonGlow(
                        VoiceRoomTokens.neonPurple,
                        blur: glow,
                      )
                    : null,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
              child: child,
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎤', style: TextStyle(fontSize: 24, height: 1)),
              Text(
                widget.micOn ? 'Açık' : 'Kapalı',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: widget.enabled
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
