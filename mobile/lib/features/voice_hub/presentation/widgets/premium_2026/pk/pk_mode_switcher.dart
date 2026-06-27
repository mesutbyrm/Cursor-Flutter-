import 'package:flutter/material.dart';

import '../../../../domain/pk/pk_battle_mode.dart';
import '../../../theme/voice_room_tokens.dart';

/// 1v1 ↔ Takım mod geçişi.
class PkModeSwitcher extends StatelessWidget {
  const PkModeSwitcher({
    super.key,
    required this.mode,
    required this.onChanged,
    this.enabled = true,
  });

  final PkBattleMode mode;
  final ValueChanged<PkBattleMode> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Chip(
            label: '1v1',
            selected: mode == PkBattleMode.oneVsOne,
            onTap: enabled ? () => onChanged(PkBattleMode.oneVsOne) : null,
          ),
          _Chip(
            label: 'Takım',
            selected: mode == PkBattleMode.team,
            onTap: enabled ? () => onChanged(PkBattleMode.team) : null,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: selected ? VoiceRoomTokens.followGradient : null,
            color: selected ? null : Colors.transparent,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
              color: selected ? Colors.white : Colors.white54,
            ),
          ),
        ),
      ),
    );
  }
}
