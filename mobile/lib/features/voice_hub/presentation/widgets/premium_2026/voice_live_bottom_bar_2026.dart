import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../theme/voice_room_tokens.dart';

/// Alt aksiyon çubuğu — Sohbet, Davet, Mikrofon, Müzik, Jeton Al.
class VoiceLiveBottomBar2026 extends StatelessWidget {
  const VoiceLiveBottomBar2026({
    super.key,
    required this.micOn,
    required this.onChat,
    required this.onInvite,
    required this.onMic,
    required this.onMusic,
    required this.onJetonStore,
    this.onEffects,
    this.onSettings,
    this.micEnabled = true,
  });

  final bool micOn;
  final bool micEnabled;
  final VoidCallback onChat;
  final VoidCallback onInvite;
  final VoidCallback onMic;
  final VoidCallback onMusic;
  final VoidCallback onJetonStore;
  final VoidCallback? onEffects;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottom + 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                _SideAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Sohbet',
                  onTap: onChat,
                ),
                _SideAction(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'Davet Et',
                  onTap: onInvite,
                ),
                Expanded(
                  child: Center(
                    child: _MicFab(
                      micOn: micOn,
                      enabled: micEnabled,
                      onTap: onMic,
                    ),
                  ),
                ),
                _SideAction(
                  icon: Icons.music_note_rounded,
                  label: 'Müzik',
                  color: VoiceRoomTokens.neonBlue,
                  onTap: onMusic,
                ),
                _SideAction(
                  icon: Icons.diamond_rounded,
                  label: 'Jeton Al',
                  color: AppColors.diamondBlue,
                  onTap: onJetonStore,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  const _SideAction({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? Colors.white70, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicFab extends StatefulWidget {
  const _MicFab({
    required this.micOn,
    required this.onTap,
    required this.enabled,
  });

  final bool micOn;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_MicFab> createState() => _MicFabState();
}

class _MicFabState extends State<_MicFab> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final glow = 16 + _pulse.value * 12;
          return Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.enabled
                  ? VoiceRoomTokens.micFabGradient
                  : LinearGradient(
                      colors: [
                        Colors.grey.shade700,
                        Colors.grey.shade800,
                      ],
                    ),
              boxShadow: widget.micOn && widget.enabled
                  ? VoiceRoomTokens.neonGlow(
                      VoiceRoomTokens.neonPurple,
                      blur: glow,
                    )
                  : null,
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
              size: 30,
            ),
            Text(
              widget.micOn ? 'Mikrofon' : 'Kapalı',
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
