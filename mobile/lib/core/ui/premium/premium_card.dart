import 'package:flutter/material.dart';

import '../../theme/canlifal_tokens.dart';

/// Neon çerçeveli cam kart — feed / profil / liste.
class PremiumCard extends StatelessWidget {
  const PremiumCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.gradientBorder,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradientBorder;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final border = gradientBorder ?? tokens.brandGradient;

    final content = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radiusCard),
        gradient: border,
      ),
      padding: const EdgeInsets.all(1.2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(tokens.radiusCard - 1),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.radiusCard),
        child: content,
      ),
    );
  }
}
