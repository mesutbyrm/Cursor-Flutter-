import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../theme/voice_room_tokens.dart';

/// Faz 6 — Alt menü: Hoparlör/Kulaklık · Müzik İste · Mikrofon · Hediye · Davet.
class VoiceRoomBottomActionBar extends StatelessWidget {
  const VoiceRoomBottomActionBar({
    super.key,
    required this.headphonesOn,
    required this.onToggleAudioOutput,
    required this.onMusicRequest,
    required this.onMusicAudio,
    required this.onMusicVideo,
    required this.micOn,
    required this.micEnabled,
    required this.onMicToggle,
    required this.onGift,
    required this.onInvite,
  });

  final bool headphonesOn;
  final VoidCallback onToggleAudioOutput;
  final VoidCallback onMusicRequest;
  final VoidCallback onMusicAudio;
  final VoidCallback onMusicVideo;
  final bool micOn;
  final bool micEnabled;
  final VoidCallback onMicToggle;
  final VoidCallback onGift;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, bottom + 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
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
                _MusicRequestAction(
                  onMainTap: onMusicRequest,
                  onAudioTap: onMusicAudio,
                  onVideoTap: onMusicVideo,
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
              Text('🎧', style: TextStyle(fontSize: 22, height: 1)),
              const SizedBox(height: 2),
              Text(
                headphonesOn ? 'Kulaklık' : 'Hoparlör',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: headphonesOn
                      ? VoiceRoomTokens.neonBlue
                      : Colors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MusicRequestAction extends StatelessWidget {
  const _MusicRequestAction({
    required this.onMainTap,
    required this.onAudioTap,
    required this.onVideoTap,
  });

  final VoidCallback onMainTap;
  final VoidCallback onAudioTap;
  final VoidCallback onVideoTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 78,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onMainTap,
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Column(
                  children: [
                    Text('🎵', style: TextStyle(fontSize: 20, height: 1)),
                    SizedBox(height: 2),
                    Text(
                      'Müzik İste',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w800,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ModeChip(label: 'Sesli', onTap: onAudioTap),
              const SizedBox(width: 3),
              _ModeChip(label: 'Videolu', onTap: onVideoTap),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
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
