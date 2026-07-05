import 'package:flutter/material.dart';

/// Destekçi rozeti kademesine göre renk paleti.
class SupporterBadgeStyle {
  const SupporterBadgeStyle(this.color, this.icon);
  final Color color;
  final IconData icon;

  static SupporterBadgeStyle of(String code) {
    switch (code.toLowerCase()) {
      case 'bronz':
        return const SupporterBadgeStyle(Color(0xFFCD7F32), Icons.shield);
      case 'gumus':
      case 'gümüş':
        return const SupporterBadgeStyle(Color(0xFFB0BEC5), Icons.shield);
      case 'altin':
      case 'altın':
        return const SupporterBadgeStyle(Color(0xFFFFC107), Icons.shield);
      case 'platin':
        return const SupporterBadgeStyle(Color(0xFF80DEEA), Icons.workspace_premium);
      case 'elmas':
        return const SupporterBadgeStyle(Color(0xFF40C4FF), Icons.diamond);
      case 'galaksi':
        return const SupporterBadgeStyle(Color(0xFFB388FF), Icons.auto_awesome);
      case 'efsane':
        return const SupporterBadgeStyle(Color(0xFFFF6E40), Icons.local_fire_department);
      default: // yeni
        return const SupporterBadgeStyle(Color(0xFF90A4AE), Icons.eco);
    }
  }
}

/// Küçük rozet pili — kademe kodu + etiket.
class SupporterBadgePill extends StatelessWidget {
  const SupporterBadgePill({
    super.key,
    required this.code,
    required this.label,
    this.compact = false,
  });

  final String code;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = SupporterBadgeStyle.of(code);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 9,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: compact ? 11 : 13, color: style.color),
          SizedBox(width: compact ? 3 : 5),
          Text(
            label,
            style: TextStyle(
              color: style.color,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 10 : 11.5,
            ),
          ),
        ],
      ),
    );
  }
}
