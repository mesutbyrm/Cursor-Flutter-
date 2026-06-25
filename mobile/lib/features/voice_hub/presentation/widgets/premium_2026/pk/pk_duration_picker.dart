import 'package:flutter/material.dart';

import '../../../../domain/pk/pk_duration_options.dart';
import '../../../theme/voice_room_tokens.dart';

/// PK daveti öncesi süre seçimi — 1 / 3 / 5 / 10 dakika.
class PkDurationPicker extends StatelessWidget {
  const PkDurationPicker({
    super.key,
    required this.selectedSeconds,
    required this.onChanged,
  });

  final int selectedSeconds;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PK Süresi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < pkDurationOptions.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _DurationChip(
                  option: pkDurationOptions[i],
                  selected: selectedSeconds == pkDurationOptions[i].seconds,
                  onTap: () => onChanged(pkDurationOptions[i].seconds),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final PkDurationOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? VoiceRoomTokens.neonPink.withValues(alpha: 0.35)
          : Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? VoiceRoomTokens.neonPink
                  : Colors.white24,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            option.shortLabel,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 13,
              color: selected ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
