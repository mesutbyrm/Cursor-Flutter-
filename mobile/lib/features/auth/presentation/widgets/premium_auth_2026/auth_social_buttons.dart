import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/ui/platform_blur.dart';
import '../../../../../core/ui/premium_2026/liquid_glass.dart';
import '../google_sign_in_button.dart';

/// Google, TikTok (yalnızca yapılandırıldığında) ve misafir giriş satırları.
/// Uygulanmamış sağlayıcılar ("yakında") gösterilmez.
class AuthSocialSection extends StatelessWidget {
  const AuthSocialSection({
    super.key,
    required this.onGoogle,
    this.onTikTok,
    this.onGuest,
    this.busy = false,
    this.googleLabel = 'Google ile devam et',
  });

  final VoidCallback? onGoogle;
  final VoidCallback? onTikTok;
  final VoidCallback? onGuest;
  final bool busy;
  final String googleLabel;

  @override
  Widget build(BuildContext context) {
    final tiktokEnabled = Env.hasTikTokLogin && onTikTok != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GoogleSignInButton(
          label: googleLabel,
          onPressed: onGoogle,
          busy: busy,
        ),
        // TikTok yalnızca gerçekten yapılandırıldığında görünür; aksi halde
        // kullanıcıya çalışmayan "yakında" butonu gösterilmez.
        if (tiktokEnabled) ...[
          const SizedBox(height: 10),
          _AuthGlassSocialButton(
            icon: Icons.music_note_rounded,
            label: 'TikTok ile devam et',
            onPressed: busy ? null : onTikTok,
          ),
        ],
        if (onGuest != null) ...[
          const SizedBox(height: 14),
          TextButton(
            onPressed: busy ? null : onGuest,
            child: Text(
              'Misafir olarak devam et',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                fontSize: 14,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _AuthGlassSocialButton extends StatelessWidget {
  const _AuthGlassSocialButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    final row = Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: context.colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        ?trailing,
      ],
    );

    final Widget glass;
    if (!PlatformBlur.supportsBackdropBlur) {
      glass = Opacity(
        opacity: enabled ? 1 : 0.55,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFF1E1638),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: row,
          ),
        ),
      );
    } else {
      glass = Opacity(
        opacity: enabled ? 1 : 0.55,
        child: LiquidGlass(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          borderRadius: BorderRadius.circular(18),
          blur: 16.0,
          child: row,
        ),
      );
    }

    if (!enabled) return glass;

    return PressableScale(onTap: onPressed!, child: glass);
  }
}

class AuthOrDividerPremium extends StatelessWidget {
  const AuthOrDividerPremium({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.white.withValues(alpha: 0.18)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'veya e-posta',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.white.withValues(alpha: 0.18)),
        ),
      ],
    );
  }
}

class AuthTextLinkPremium extends StatelessWidget {
  const AuthTextLinkPremium({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: Color(0xFFE9D5FF),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
