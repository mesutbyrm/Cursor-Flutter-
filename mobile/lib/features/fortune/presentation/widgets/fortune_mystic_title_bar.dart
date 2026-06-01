import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'fortune_hub_gold_stars.dart';
import 'fortune_mystic_bar_button.dart';

/// Altın serif başlık + geri / sağ aksiyon (günlük fal mockup).
class FortuneMysticTitleBar extends StatelessWidget {
  const FortuneMysticTitleBar({
    super.key,
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  static const _goldLight = Color(0xFFF5E6C8);
  static const _goldMid = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final titleStyle = GoogleFonts.playfairDisplay(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.1,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(12, top + 6, 12, 10),
      child: Row(
        children: [
          FortuneMysticBarButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onPressed: onBack,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 11, color: _goldMid),
                const SizedBox(width: 6),
                Flexible(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [_goldLight, _goldMid, Color(0xFFE9C46A)],
                    ).createShader(bounds),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.auto_awesome, size: 11, color: _goldMid),
              ],
            ),
          ),
          trailing ??
              const SizedBox(width: 40, height: 40),
        ],
      ),
    );
  }
}

/// Başlık altı tek altın yıldız ayırıcı.
class FortuneMysticStarDivider extends StatelessWidget {
  const FortuneMysticStarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: FortuneHubGoldStars(size: 12, spacing: 2),
    );
  }
}
