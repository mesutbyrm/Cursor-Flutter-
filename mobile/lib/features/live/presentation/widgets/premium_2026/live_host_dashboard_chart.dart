import 'package:flutter/material.dart';

/// Mini sparkline — yayıncı dashboard grafikleri.
class LiveHostDashboardChart extends StatelessWidget {
  const LiveHostDashboardChart({
    super.key,
    required this.label,
    required this.values,
    required this.color,
  });

  final String label;
  final List<int> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final data = values.isEmpty ? [0] : values;
    final max = data.reduce((a, b) => a > b ? a : b).clamp(1, 999999);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final v in data)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 48 * (v / max),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
