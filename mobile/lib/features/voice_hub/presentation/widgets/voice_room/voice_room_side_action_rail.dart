import 'package:flutter/material.dart';

import '../../theme/voice_room_tokens.dart';

/// Web parity — sağ kenar orta hizada ayarlar + müzik kısayolları.
class VoiceRoomSideActionRail extends StatelessWidget {
  const VoiceRoomSideActionRail({
    super.key,
    this.onSettings,
    this.onMusic,
    this.showMusic = true,
    /// Dikey hizalama: -1 üst, 0 orta, 1 alt. Web gibi hafif aşağıda.
    this.verticalAlignment = 0.12,
  });

  final VoidCallback? onSettings;
  final VoidCallback? onMusic;
  final bool showMusic;
  final double verticalAlignment;

  @override
  Widget build(BuildContext context) {
    if (onSettings == null && (!showMusic || onMusic == null)) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      right: 8,
      bottom: 0,
      child: Align(
        alignment: Alignment(1, verticalAlignment.clamp(-1.0, 1.0)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onSettings != null)
              _SideActionButton(
                icon: Icons.settings_rounded,
                label: 'Ayarlar',
                color: VoiceRoomTokens.neonBlue,
                onTap: onSettings!,
              ),
            if (onSettings != null && showMusic && onMusic != null)
              const SizedBox(height: 12),
            if (showMusic && onMusic != null)
              _SideActionButton(
                icon: Icons.library_music_rounded,
                label: 'Müzik',
                color: VoiceRoomTokens.gold,
                onTap: onMusic!,
              ),
          ],
        ),
      ),
    );
  }
}

class _SideActionButton extends StatelessWidget {
  const _SideActionButton({
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
    return Material(
      color: Colors.black.withValues(alpha: 0.42),
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: color.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.55)),
            boxShadow: VoiceRoomTokens.neonGlow(color, blur: 10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
