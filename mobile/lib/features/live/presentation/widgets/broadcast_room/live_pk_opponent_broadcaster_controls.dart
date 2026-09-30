import 'package:flutter/material.dart';

/// PK rakip paneli — yalnızca yayıncı: karşı taraf sesini kapat + PK bitir.
class LivePkOpponentBroadcasterControls extends StatelessWidget {
  const LivePkOpponentBroadcasterControls({
    super.key,
    required this.opponentMuted,
    required this.onToggleOpponentMute,
    this.onEndPk,
  });

  final bool opponentMuted;
  final VoidCallback onToggleOpponentMute;
  final VoidCallback? onEndPk;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleAction(
          icon: opponentMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
          label: opponentMuted ? 'Ses kapalı' : 'Rakip sesi',
          onTap: onToggleOpponentMute,
          accent: opponentMuted ? Colors.orangeAccent : Colors.white70,
        ),
        if (onEndPk != null) ...[
          const SizedBox(width: 14),
          _CircleAction(
            icon: Icons.close_rounded,
            label: 'PK bitir',
            onTap: onEndPk,
            accent: const Color(0xFFE53935),
            filled: true,
          ),
        ],
      ],
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.accent,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color accent;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? accent.withValues(alpha: 0.92)
          : Colors.black.withValues(alpha: 0.55),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, color: filled ? Colors.white : accent, size: 24),
        ),
      ),
    );
  }
}
