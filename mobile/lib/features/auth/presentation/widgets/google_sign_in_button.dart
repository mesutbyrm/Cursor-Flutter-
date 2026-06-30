import 'package:flutter/material.dart';
import 'package:canlifal_social/core/theme/app_theme_colors.dart';
import 'package:canlifal_social/core/theme/app_theme_extensions.dart';

import '../../../../core/config/google_auth_config.dart';

/// Google ile giriş — birincil CTA (beyaz zemin + G rozeti).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.primary = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final bool primary;

  bool get _enabled =>
      !busy && onPressed != null && GoogleAuthConfig.isConfigured;

  @override
  Widget build(BuildContext context) {
    final configured = GoogleAuthConfig.isConfigured;

    if (primary) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: configured ? Colors.white : Colors.white.withValues(alpha: 0.35),
              boxShadow: configured
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.28),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
              child: _row(context, darkText: true),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF16162A).withValues(alpha: 0.92),
            border: Border.all(
              color: AppThemeColors.accentPurple.withValues(alpha: 0.35),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
            child: _row(context, darkText: false),
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, {required bool darkText}) {
    final textColor = darkText
        ? const Color(0xFF1F1F1F)
        : context.colors.onSurface;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (busy)
          SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: darkText ? const Color(0xFF4285F4) : AppThemeColors.accentPink,
            ),
          )
        else ...[
          const _GoogleGlyph(),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              configuredLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: -0.2,
                color: textColor.withValues(alpha: _enabled ? 1 : 0.55),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String get configuredLabel {
    if (GoogleAuthConfig.isConfigured) return label;
    return 'Google giriş yapılandırılmamış';
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) {
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF4285F4),
              Color(0xFFEA4335),
              Color(0xFFFBBC05),
              Color(0xFF34A853),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ).createShader(bounds);
        },
        child: const Text(
          'G',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}
