import 'package:flutter/material.dart';

import '../../../../../core/config/env.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/ui/premium_2026/liquid_glass.dart';
import '../../../../../core/ui/premium_2026/premium_motion.dart';
import '../google_sign_in_button.dart';

/// Google, TikTok, Apple ve misafir giriş satırları.
class AuthSocialSection extends StatelessWidget {
  const AuthSocialSection({
    super.key,
    required this.onGoogle,
    this.onTikTok,
    this.onApple,
    this.onGuest,
    this.busy = false,
    this.googleLabel = 'Google ile devam et',
  });

  final VoidCallback? onGoogle;
  final VoidCallback? onTikTok;
  final VoidCallback? onApple;
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
        const SizedBox(height: 10),
        _AuthGlassSocialButton(
          icon: Icons.music_note_rounded,
          label: tiktokEnabled ? 'TikTok ile devam et' : 'TikTok (yakında)',
          onPressed: tiktokEnabled && !busy ? onTikTok : null,
          trailing: tiktokEnabled ? null : _soonBadge(),
        ),
        const SizedBox(height: 10),
        _AuthGlassSocialButton(
          icon: Icons.apple_rounded,
          label: 'Apple ile devam et',
          onPressed: !busy ? onApple : null,
          trailing: _soonBadge(),
        ),
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

  static Widget _soonBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.accentCyan.withValues(alpha: 0.15),
        border: Border.all(
          color: AppColors.accentCyan.withValues(alpha: 0.35),
        ),
      ),
      child: const Text(
        'Yakında',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.accentCyan,
        ),
      ),
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

    final glass = Opacity(
        opacity: enabled ? 1 : 0.55,
        child: LiquidGlass(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          borderRadius: BorderRadius.circular(18),
          blur: 16,
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      );

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
        style: const TextStyle(
          color: Color(0xFFE9D5FF),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}
