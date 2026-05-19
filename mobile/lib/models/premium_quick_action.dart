import 'package:flutter/material.dart';

@immutable
class PremiumQuickAction {
  const PremiumQuickAction({
    required this.title,
    required this.icon,
    required this.gradientIndex,
  });

  final String title;
  final IconData icon;
  final int gradientIndex;
}
