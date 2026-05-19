import 'package:flutter/material.dart';

@immutable
class PremiumTarotOffer {
  const PremiumTarotOffer({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.borderGradient,
    required this.cardGradient,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Gradient borderGradient;
  final Gradient cardGradient;
}
