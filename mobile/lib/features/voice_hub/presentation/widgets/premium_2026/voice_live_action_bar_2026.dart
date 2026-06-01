import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../theme/voice_room_tokens.dart';

/// PART 3 — Alt action bar: mic merkez, hediye, müzik, efekt, davet, ayarlar.
class VoiceLiveActionBar2026 extends StatelessWidget {
  const VoiceLiveActionBar2026({
    super.key,
    required this.micOn,
    required this.micEnabled,
    required this.onMic,
    required this.onGift,
    required this.onMusic,
    required this.onEffects,
    required this.onInvite,
    required this.onSettings,
    this.onChat,
  });

  final bool micOn;
  final bool micEnabled;
  final VoidCallback onMic;
  final VoidCallback onGift;
  final VoidCallback onMusic;
  final VoidCallback onEffects;
  final VoidCallback onInvite;
  final VoidCallback onSettings;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(10, 0, 10, bottom + 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: VoiceRoomTokens.neonPurple.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                _Action(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Hediye',
                  color: VoiceRoomTokens.gold,
                  onTap: onGift,
                ),
                _Action(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Davet',
                  onTap: onInvite,
                ),
                _Action(
                  icon: Icons.music_note_rounded,
                  label: 'Müzik',
                  color: VoiceRoomTokens.neonBlue,
                  onTap: onMusic,
                ),
                Expanded(
                  child: Center(
                    child: _CenterMicFab(
                      micOn: micOn,
                      enabled: micEnabled,
                      onTap: onMic,
                    ),
                  ),
                ),
                _Action(
                  icon: Icons.graphic_eq_rounded,
                  label: 'Efekt',
                  color: VoiceRoomTokens.neonPink,
                  onTap: onEffects,
                ),
                _Action(
                  icon: Icons.tune_rounded,
                  label: 'Ayarlar',
                  onTap: onSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
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
              Icon(icon, color: color ?? Colors.white70, size: 22),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterMicFab extends StatefulWidget {
  const _CenterMicFab({
    required this.micOn,
    required this.enabled,
    required this.onTap,
  });

  final bool micOn;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_CenterMicFab> createState() => _CenterMicFabState();
}

class _CenterMicFabState extends State<_CenterMicFab>
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
      offset: const Offset(0, -14),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final glow = widget.micOn && widget.enabled
                ? 18 + _pulse.value * 14
                : 0.0;
            return Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.enabled
                    ? VoiceRoomTokens.micFabGradient
                    : const LinearGradient(
                        colors: [Color(0xFF444444), Color(0xFF222222)],
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
              Icon(
                widget.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                color: Colors.white,
                size: 32,
              ),
              Text(
                widget.micOn ? 'Açık' : 'Kapalı',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: widget.micOn
                      ? Colors.white
                      : AppColors.liveRed.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
