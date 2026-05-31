import 'package:flutter/material.dart';

import '../../../../../core/ui/premium/premium_section_header.dart';

/// Keşfet bölüm başlığı — premium section header sarmalayıcı.
class DiscoverSectionHeader extends StatelessWidget {
  const DiscoverSectionHeader({
    super.key,
    required this.title,
    this.actionLabel = 'Tümünü gör',
    this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return PremiumSectionHeader(
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
