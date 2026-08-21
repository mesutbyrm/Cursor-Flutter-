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
            padding: EdgeInsets.only(bottom: row == rows - 1 ? 0 : 8),
            child: Row(
              children: List.generate(columns, (col) {
                final index = row * columns + col;
                if (index >= board.length) {
                  return const Expanded(child: SizedBox());
                }
                final value = board[index];
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: col == columns - 1 ? 0 : 8),
                    child: _BoardCell(
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
  });

  final String? value;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = value?.trim();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: context.colors.surfaceContainer.withValues(alpha: 0.65),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
            ),
          ),
          child: Center(
            child: Text(
              label == null || label.isEmpty ? '' : label,
              style: TextStyle(
                fontSize: 28,
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
