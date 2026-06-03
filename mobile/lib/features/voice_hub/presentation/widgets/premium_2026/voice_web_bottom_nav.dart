import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';

import '../../theme/voice_room_tokens.dart';

/// Web alt navigasyon — Ana Sayfa, Hoparlör, merkez mikrofon, Jeton, Ayarlar.
class VoiceWebBottomNav extends StatelessWidget {
  const VoiceWebBottomNav({
    super.key,
    required this.micOn,
    required this.micEnabled,
    required this.onHome,
    required this.onSpeaker,
    required this.onMic,
    required this.onCoins,
    required this.onSettings,
    this.headphonesOn = false,
  });

  final bool micOn;
  final bool micEnabled;
  final bool headphonesOn;
  final VoidCallback onHome;
  final VoidCallback onSpeaker;
  final VoidCallback onMic;
  final VoidCallback onCoins;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: EdgeInsets.fromLTRB(8, 10, 8, bottom + 10),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.72),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'Ana Sayfa',
                onTap: onHome,
              ),
              _NavItem(
                icon: headphonesOn
                    ? Icons.headphones_rounded
                    : Icons.volume_up_rounded,
                label: 'Hoparlör',
                onTap: onSpeaker,
                highlight: headphonesOn,
              ),
              Expanded(
                child: Center(
                  child: _CenterMicButton(
                    micOn: micOn,
                    enabled: micEnabled,
                    onTap: onMic,
                  ),
                ),
              ),
              _NavItem(
                icon: Icons.monetization_on_rounded,
                label: 'Jeton Yükle',
                color: AppThemeColors.diamondBlue,
                onTap: onCoins,
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Ayarlar',
                color: VoiceRoomTokens.neonBlue,
                onTap: onSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: highlight
                  ? VoiceRoomTokens.neonBlue
                  : (color ?? Colors.white.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                height: 1.1,
                color: color ?? Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
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
      duration: const Duration(milliseconds: 1400),
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
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final glow = widget.micOn && widget.enabled
              ? 18 + _pulse.value * 14
              : 0.0;
          return Container(
            width: 76,
            height: 76,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.enabled
                  ? VoiceRoomTokens.micFabGradient
                  : LinearGradient(
                      colors: [Colors.grey.shade700, Colors.grey.shade900],
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
        child: Icon(
          widget.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }
}

/// Sağ kenar — ‹ oda araçları, ♫ müzik isteği (canlifal.com).
class VoiceWebFloatingRail extends StatelessWidget {
  const VoiceWebFloatingRail({
    super.key,
    this.onTools,
    this.onMusic,
  });

  final VoidCallback? onTools;
  final VoidCallback? onMusic;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _FloatBtn(icon: Icons.chevron_left_rounded, onTap: onTools),
        const SizedBox(height: 10),
        _FloatBtn(icon: Icons.queue_music_rounded, onTap: onMusic),
      ],
    );
  }
}

class _FloatBtn extends StatelessWidget {
  const _FloatBtn({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
        ),
      ),
    );
  }
}
