import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../theme/voice_room_tokens.dart';
import 'voice_glass.dart';

class VoicePremiumControls extends StatelessWidget {
  const VoicePremiumControls({
    super.key,
    required this.micOn,
    required this.headphonesOn,
    required this.onMic,
    required this.onHeadphones,
    required this.onRequestSpeak,
    required this.onEffects,
    required this.onMore,
  });

  final bool micOn;
  final bool headphonesOn;
  final VoidCallback onMic;
  final VoidCallback onHeadphones;
  final VoidCallback onRequestSpeak;
  final VoidCallback onEffects;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return VoiceGlass(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ControlItem(
            icon: micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            label: micOn ? 'Açık' : 'Kapalı',
            color: micOn ? AppColors.onlineGreen : AppColors.textMuted,
            onTap: onMic,
          ),
          _ControlItem(
            icon: headphonesOn
                ? Icons.headphones_rounded
                : Icons.headset_off_rounded,
            label: headphonesOn ? 'Açık' : 'Kapalı',
            color: VoiceRoomTokens.neonBlue,
            onTap: onHeadphones,
          ),
          _ControlItem(
            icon: Icons.front_hand_rounded,
            label: 'Söz İste',
            color: VoiceRoomTokens.neonPurple,
            onTap: onRequestSpeak,
          ),
          _ControlItem(
            icon: Icons.graphic_eq_rounded,
            label: 'Efekt',
            color: AppColors.accentPink,
            onTap: onEffects,
          ),
          _ControlItem(
            icon: Icons.more_horiz_rounded,
            label: 'Daha Fazla',
            color: Colors.white70,
            onTap: onMore,
          ),
        ],
      ),
    );
  }
}

class _ControlItem extends StatelessWidget {
  const _ControlItem({
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.18),
                border: Border.all(color: color.withValues(alpha: 0.45)),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
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
