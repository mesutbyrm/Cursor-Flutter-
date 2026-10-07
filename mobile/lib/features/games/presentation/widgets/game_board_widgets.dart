import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme_extensions.dart';

/// XOX ve benzeri grid oyunları için dokunma alanı geniş tahta.
class GameBoardPanel extends StatelessWidget {
  const GameBoardPanel({
    super.key,
    required this.board,
    required this.onCellTap,
    this.enabled = true,
    this.columns = 3,
  });

  final List<String?> board;
  final ValueChanged<int> onCellTap;
  final bool enabled;
  final int columns;

  @override
  Widget build(BuildContext context) {
    final rows = (board.length / columns).ceil();
    // NxN XOX (6/8/10): küçük boşluk, kare hücre, ölçekli yazı.
    final gap = columns <= 3 ? 8.0 : 2.0;
    final compact = columns > 3;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: context.colors.surface.withValues(alpha: 0.72),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: List.generate(rows, (row) {
          return Padding(
            padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : gap),
            child: Row(
              children: List.generate(columns, (col) {
                final index = row * columns + col;
                if (index >= board.length) {
                  return const Expanded(child: SizedBox());
                }
                final value = board[index];
                return Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: col == columns - 1 ? 0 : gap),
                    child: _BoardCell(
                      compact: compact,
                      fontSize: compact ? (84 / columns).clamp(10, 20) : 28,
                      value: value,
                      enabled: enabled && (value == null || value.isEmpty),
                      onTap: () => onCellTap(index),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}

class _BoardCell extends StatelessWidget {
  const _BoardCell({
    required this.value,
    required this.enabled,
    required this.onTap,
    this.compact = false,
    this.fontSize = 28,
  });

  final bool compact;
  final double fontSize;
  final String? value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = value?.trim();
    final cell = _cell(context, label);
    return compact ? AspectRatio(aspectRatio: 1, child: cell) : cell;
  }

  Widget _cell(BuildContext context, String? label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(compact ? 4 : 16),
        child: Ink(
          height: compact ? null : 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 4 : 16),
            color: context.colors.surfaceContainer.withValues(alpha: 0.65),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
            ),
          ),
          child: Center(
            child: Text(
              label == null || label.isEmpty ? '' : label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                color: label == 'X'
                    ? const Color(0xFF8B5CF6)
                    : label == 'O'
                    ? const Color(0xFFEC4899)
                    : context.colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
