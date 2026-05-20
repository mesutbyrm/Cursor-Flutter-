import 'package:flutter/material.dart';

import 'glow_panel.dart';

/// Hızlı işlem kutusu — ana sayfa ve sekmelerde ortak.
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 28, color: Colors.white.withValues(alpha: 0.95)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// [QuickActionTile] satırları (satır başına 2 kutu).
class QuickActionGrid extends StatelessWidget {
  const QuickActionGrid({super.key, required this.rows});

  final List<List<QuickActionTile>> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            children: [
              for (var j = 0; j < rows[i].length; j++) ...[
                if (j > 0) const SizedBox(width: 10),
                Expanded(child: rows[i][j]),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// Bölüm + kısayol ızgarası (GlowPanel içinde).
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({
    super.key,
    required this.sectionIcon,
    required this.sectionTitle,
    required this.accent,
    required this.rows,
  });

  final IconData sectionIcon;
  final String sectionTitle;
  final Color accent;
  final List<List<QuickActionTile>> rows;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlowPanel(
        borderRadius: 18,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitleRow(
              icon: sectionIcon,
              title: sectionTitle,
              accent: accent,
            ),
            const SizedBox(height: 12),
            QuickActionGrid(rows: rows),
          ],
        ),
      ),
    );
  }
}
