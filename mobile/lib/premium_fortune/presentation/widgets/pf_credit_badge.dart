import 'package:flutter/material.dart';

import '../../core/theme/pf_theme.dart';

class PfCreditBadge extends StatelessWidget {
  const PfCreditBadge({super.key, required this.credits});

  final int credits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [PfTheme.gold, Color(0xFFB8860B)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on_rounded, size: 16, color: Colors.black87),
          const SizedBox(width: 4),
          Text(
            '$credits',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
