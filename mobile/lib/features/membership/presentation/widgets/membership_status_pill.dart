import 'package:flutter/material.dart';

/// Üyelik durum pill — hub istatistik / growth hub kartı.
class MembershipStatusPill extends StatelessWidget {
  const MembershipStatusPill({
    super.key,
    required this.label,
    this.expired = false,
  });

  final String label;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: expired
              ? const [Color(0xFF9CA3AF), Color(0xFF6B7280)]
              : const [Color(0xFFFFD54F), Color(0xFFFFB300)],
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: expired ? const Color(0xFF111827) : const Color(0xFF1A1030),
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
