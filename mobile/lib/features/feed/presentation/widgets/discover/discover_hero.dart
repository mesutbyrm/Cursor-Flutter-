import 'package:flutter/material.dart';

import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

class DiscoverHeroHeadline extends StatelessWidget {
  const DiscoverHeroHeadline({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final base = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      height: 1.25,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: RichText(
        text: TextSpan(
          style: base,
          children: [
            const TextSpan(text: 'Canlı yayınlara '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: ShaderMask(
                shaderCallback: (b) =>
                    tokens.brandGradient.createShader(b),
                child: Text(
                  'katıl, eğlenceye',
                  style: base?.copyWith(color: Colors.white),
                ),
              ),
            ),
            const TextSpan(text: ' ortak ol! ❤️'),
          ],
        ),
      ),
    );
  }
}
