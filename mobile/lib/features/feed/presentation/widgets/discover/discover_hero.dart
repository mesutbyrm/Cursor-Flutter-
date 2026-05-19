import 'package:flutter/material.dart';

import '../../../../../core/theme/app_design.dart';

class DiscoverHeroHeadline extends StatelessWidget {
  const DiscoverHeroHeadline({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 26,
            height: 1.25,
            fontWeight: FontWeight.w800,
            color: AppDesign.textPrimary,
            letterSpacing: -0.5,
          ),
          children: [
            const TextSpan(text: 'Canlı yayınlara '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: ShaderMask(
                shaderCallback: (b) => AppDesign.heroGradient.createShader(b),
                child: const Text(
                  'katıl, eğlenceye',
                  style: TextStyle(
                    fontSize: 26,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
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
